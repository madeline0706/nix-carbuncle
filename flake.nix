{
  description = "Carbuncle - Ran on my Pi Zero 2W :3";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    sops-nix = {                          # age-encrypted secrets
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs"; # pin sops-nix to our nixpkgs, no second copy
    };
  };

  outputs = { nixpkgs, sops-nix, ... }:
    let
      # shared base for both configs below
      modules = [
        sops-nix.nixosModules.sops
        ./configuration.nix
      ];
    in {
      # flashable SD image for the first install; sd-image module brings its own
      # fs/boot layout (root by-label NIXOS_SD), so it doesn't use hardware.nix

      nixosConfigurations.carbuncle-image = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";           # siren is aarch64, so build/cross-build for it
        modules = modules ++ [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ];
      };

      # the real running system: what ./deploy switches to
      nixosConfigurations.carbuncle = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = modules ++ [ ./hardware.nix ]; # adds the actual disk/boot layout
      };
    };
}
