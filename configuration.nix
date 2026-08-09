{ config, lib, pkgs, ... }:
{
  imports = [ ./site.nix ];

  system.stateVersion = "26.05";

  networking = {
    hostName = "carbuncle";
    useDHCP = lib.mkDefault true;
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.sops.secrets."tailscale/authkey".path;
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

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.secrets."tailscale/authkey" = { };
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
    Storage=persistent
    SystemMaxUse=50M
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

  services.spellboundSite.enable = true;

  environment.systemPackages = with pkgs; [ usbutils fastfetch ];
}
