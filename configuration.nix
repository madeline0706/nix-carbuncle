{ lib, pkgs, ... }:
{
  system.stateVersion = "26.05";

  networking = {
    hostName = "carbuncle";
    useDHCP = lib.mkDefault true;
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = "${pkgs.writeText "ts-authkey"
      "tskey-auth-k6QEyqva9411CNTRL-JMACqiFV4mGP7Sv8uXgDmGtaB6xmhA6n"}";
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOARmU1gT1eVnYO4yA9TRBbY6DRirqQXjWKnpa+5eMbv madeline@bulbasaur-nix"
  ];

  users.users.madeline = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOARmU1gT1eVnYO4yA9TRBbY6DRirqQXjWKnpa+5eMbv madeline@bulbasaur-nix"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  sops.age = {
    keyFile = "/var/lib/sops-nix/key.txt";
    generateKey = false;
    sshKeyPaths = [ ];
  };
  sops.gnupg.sshKeyPaths = [ ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  services.earlyoom.enable = true;

  services.udisks2.enable = false;

  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=32M
  '';

  fileSystems."/".options = [ "noatime" ];

  nix = {
    settings = {
      auto-optimise-store = true;
      min-free = 512 * 1024 * 1024;
      max-free = 2 * 1024 * 1024 * 1024;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 3d";
    };
    optimise.automatic = true;
  };

  boot.kernelModules = [ "bcm2835_wdt" ];
  systemd.watchdog = {
    runtimeTime = "20s";
    rebootTime = "30s";
  };

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible = {
    enable = true;
    configurationLimit = 3;
  };
  boot.supportedFilesystems.zfs = lib.mkForce false;

  hardware.enableRedistributableFirmware = true;

  documentation.enable = false;
  documentation.nixos.enable = false;

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  programs.command-not-found.enable = false;
  environment.defaultPackages = lib.mkForce [ ];

  environment.systemPackages = with pkgs; [ usbutils fastfetch ];
}
