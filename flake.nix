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

      # --- local dev on shiva (x86_64); none of this ships to carbuncle ---
      devSystem = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${devSystem};

      # the exact tree that deploys, built natively for local preview
      site = import ./site-pkg.nix { inherit pkgs; };

      # reproducible preview: build the site derivation and serve it as-is
      serve = pkgs.writeShellApplication {
        name = "carbuncle-serve";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          port="''${1:-8000}"
          echo "serving ${site} at http://localhost:$port  (Ctrl-C to stop)"
          cd ${site}
          exec python3 -m http.server "$port"
        '';
      };
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

      # `nix build .#site`  -> the served tree in ./result (verify the real build)
      packages.${devSystem} = {
        site = site;
        default = site;
      };

      # `nix run .#serve [port]`  -> build + serve on localhost (reproducible)
      apps.${devSystem}.serve = {
        type = "app";
        program = "${serve}/bin/carbuncle-serve";
      };

      # `nix develop`  -> shell with everything ./dev.sh needs for the fast loop
      devShells.${devSystem}.default = pkgs.mkShell {
        packages = with pkgs; [ cmark-gfm coreutils gnused gawk bash python3 entr ];
        LORA = pkgs.lora;        # ./dev.sh copies the served fonts from here
        HACK = pkgs.hack-font;   # code-block + terminal monospace
        shellHook = ''
          echo "carbuncle dev shell — ./dev.sh watch   (live-rebuild + serve on :8000)"
          echo "                      ./dev.sh build   (render once into .dev-site/)"
        '';
      };
    };
}
