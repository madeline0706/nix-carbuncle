{ config, lib, pkgs, ... }:
{
  imports = [ ./site.nix ];

  system.stateVersion = "26.05";

  # set hostname, use DHCP, trust the tailscale interface

  networking = {
    hostName = "carbuncle";
    useDHCP = lib.mkDefault true;
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  # tailscale settings, *attempt* to use encrypted authkey

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.sops.secrets."tailscale/authkey".path;
  };

  # ssh settings, passwordless sudo! scary. use my public key

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOARmU1gT1eVnYO4yA9TRBbY6DRirqQXjWKnpa+5eMbv madeline@bulbasaur-nix"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2OMMWXTrcZ2Dl+N0GjstqnFQlspF0ofQ2SZkfKwJX+ madeline@arcanine-nix"
  ];

  # holy shit who's that?

  users.users.madeline = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOARmU1gT1eVnYO4yA9TRBbY6DRirqQXjWKnpa+5eMbv madeline@bulbasaur-nix"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2OMMWXTrcZ2Dl+N0GjstqnFQlspF0ofQ2SZkfKwJX+ madeline@arcanine-nix"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # sops stuff

  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.secrets."tailscale/authkey" = { };
  sops.age = {
    keyFile = "/var/lib/sops-nix/key.txt";
    generateKey = false;
    sshKeyPaths = [ ];
  };
  sops.gnupg.sshKeyPaths = [ ];

  # 512mb of ram, what could go wrong?

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  # experimenting with this one

  services.earlyoom.enable = true;

  services.udisks2.enable = false;

  # may adjust later, trying to trim down on i/o for the poor poor sd card

  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=50M
  '';

  # less i/o

  fileSystems."/".options = [ "noatime" ];

  # use less storage, only got 32GB to work with

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

  # my beloved grub, what did they do to you

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible = {
    enable = true;
    configurationLimit = 3;
  };
  boot.supportedFilesystems.zfs = lib.mkForce false;

  hardware.enableRedistributableFirmware = true;

  # bloat!

  documentation.enable = false;
  documentation.nixos.enable = false;

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  programs.command-not-found.enable = false;
  environment.defaultPackages = lib.mkForce [ ];

  # the big one

  services.spellboundSite.enable = true;

  # gotta have fastfetch!

  environment.systemPackages = with pkgs; [ usbutils fastfetch ];
}
