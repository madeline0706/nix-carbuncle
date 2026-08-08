{
  description = "Raspberry Pi Zero 2 W — headless NixOS, built on the Pi 5";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, sops-nix, ... }:
    let
      modules = [
        sops-nix.nixosModules.sops
        ./configuration.nix
      ];
    in {
      nixosConfigurations.carbuncle-image = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = modules ++ [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ];
      };

      nixosConfigurations.carbuncle = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = modules ++ [ ./hardware.nix ];
      };
    };
}
