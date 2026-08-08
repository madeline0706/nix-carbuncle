{ lib, pkgs, ... }:
{
  system.stateVersion = "26.05";

  networking = {
    hostName = "carbuncle";
    # DHCP on whatever the USB-OTG ethernet dongle enumerates as — this is
    # just the uplink Tailscale rides over, not an access path itself.
    useDHCP = lib.mkDefault true;
    # SSH is NOT exposed on the physical uplink. The only interface we
    # trust is the tailnet; access comes in over tailscale0.
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  # Tailscale is the sole way in. tailscaled brings the node up on the
  # tailnet at boot using the baked-in auth key, and Tailscale SSH (--ssh)
  # handles remote login. OpenSSH also stays enabled, key-based, reachable
  # only over tailscale0 (trusted above) as an in-tailnet fallback.
  services.tailscale = {
    enable = true;
    openFirewall = true; # WireGuard UDP port, for direct (non-relayed) links
    authKeyFile = "${pkgs.writeText "ts-authkey"
      "tskey-auth-k6QEyqva9411CNTRL-JMACqiFV4mGP7Sv8uXgDmGtaB6xmhA6n"}";
    extraUpFlags = [ "--ssh" ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Key-based root login. With Tailscale SSH enabled this is a secondary
  # path, still reachable only from within the tailnet.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOARmU1gT1eVnYO4yA9TRBbY6DRirqQXjWKnpa+5eMbv madeline@bulbasaur-nix"
  ];

  # Primary human account, in wheel for sudo.
  users.users.madeline = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOARmU1gT1eVnYO4yA9TRBbY6DRirqQXjWKnpa+5eMbv madeline@bulbasaur-nix"
    ];
  };

  # Key-only login with no user password, so wheel sudos without one.
  # Tradeoff: anyone who gets an SSH session as a wheel user is root.
  security.sudo.wheelNeedsPassword = false;

  # sops-nix: plumbing only for now, no secrets declared yet.
  #
  # Decryption uses a STANDALONE age key that must be provisioned out-of-store
  # onto the card's ext4 root at /var/lib/sops-nix/key.txt AFTER flashing
  # (see NOTES). It is never committed to git or placed in the Nix store.
  #
  # To add a secret later:
  #   1. put its public age recipient in .sops.yaml
  #   2. `sops secrets/secrets.yaml` to create/edit the encrypted file
  #   3. declare it here, e.g.
  #        sops.defaultSopsFile = ./secrets/secrets.yaml;
  #        sops.secrets."tailscale/authkey" = { };
  #      and point the consumer at config.sops.secrets."tailscale/authkey".path
  sops.age = {
    keyFile = "/var/lib/sops-nix/key.txt";
    generateKey = false;
    # Use the standalone key only — do not also derive keys from SSH host keys.
    sshKeyPaths = [ ];
  };
  sops.gnupg.sshKeyPaths = [ ];

  # 512 MB is not a lot of megabytes.
  zramSwap.enable = true;

  # Aggressive store hygiene — this is a 32 GB microSD and it fills fast.
  nix = {
    settings = {
      # Hardlink identical files in the store together (dedup on disk).
      auto-optimise-store = true;
      # If the store drops below min-free during a copy/build, free space
      # by GC'ing until max-free is available again. Keeps deploys from
      # ever wedging the card at 100%.
      min-free = 512 * 1024 * 1024;      # 512 MB
      max-free = 2 * 1024 * 1024 * 1024; # 2 GB
    };
    # Scheduled GC: drop anything older than 3 days, weekly.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 3d";
    };
    # Periodically re-run the hardlink optimiser as well.
    optimise.automatic = true;
  };

  # Keep only a couple of bootable generations; each one pins a full
  # system closure on the card.
  boot.loader.generic-extlinux-compatible.configurationLimit = 3;

  hardware.enableRedistributableFirmware = true;

  # Trims closure size without flipping options the aarch64 binary cache
  # isn't built against (which is why we avoid profiles/minimal.nix).
  documentation.enable = false;
  documentation.nixos.enable = false;

  environment.systemPackages = with pkgs; [ usbutils ];
}
