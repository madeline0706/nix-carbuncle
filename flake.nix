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
      # Shared module list so the image and the running system can't drift.
      modules = [
        sops-nix.nixosModules.sops
        ./configuration.nix
      ];
    in {
      # Build the flashable SD image with:
      #   nix build .#nixosConfigurations.carbuncle-image.config.system.build.sdImage
      nixosConfigurations.carbuncle-image = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = modules ++ [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ];
      };

      # Deploy after first boot with:
      #   nixos-rebuild switch --flake .#carbuncle --target-host root@carbuncle
      nixosConfigurations.carbuncle = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        inherit modules;
      };
    };
}
