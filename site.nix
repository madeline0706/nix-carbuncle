{ config, lib, pkgs, ... }:

let
  cfg = config.services.spellboundSite;

  # build derivation, render the blog from markdown, and bundle the fonts
  blog = pkgs.runCommand "spellbound-blog"
    # tools blog-generate.sh needs
    { nativeBuildInputs = with pkgs; [ cmark-gfm coreutils gnused gawk bash ]; }
    ''
      bash ${./blog-generate.sh} ${cfg.blogSrc} $out   # generate HTML into $out from the blog source
      mkdir -p $out/fonts
      cp ${cfg.loraFont}/share/fonts/truetype/'Lora[wght].ttf' $out/fonts/Lora.ttf              # serve Lora under /fonts
      cp ${cfg.loraFont}/share/fonts/truetype/'Lora-Italic[wght].ttf' $out/fonts/Lora-Italic.ttf # don't forget about italic
      cp ${./fonts/OFL.txt} $out/fonts/OFL.txt                                                   # SIL OFL travels with the served font (nixpkgs' lora ships no license)
    '';

  # assemble the final served tree: blog at the root, static terminal app at /terminal
  site = pkgs.runCommand "spellbound-site" { } ''
    mkdir -p $out
    cp -r ${blog}/. $out/                  # generated blog becomes the site root
    cp -r ${cfg.terminalSrc} $out/terminal # parked terminal app mounted at /terminal
  '';
in
{
  # custom site module API: bibs n' knobs for the site, with sensible? defaults
  options.services.spellboundSite = {
    enable = lib.mkEnableOption "the spellbound.sh blog";

    blogSrc = lib.mkOption {           # where the blog markdown + templates live
      type = lib.types.path;
      default = ./site/blog;
      description = "Markdown + template sources for the blog.";
    };

    loraFont = lib.mkOption {          # font package copied into /fonts
      type = lib.types.package;
      default = pkgs.lora;
      description = "The Lora font package, served under /fonts.";
    };

    terminalSrc = lib.mkOption {       # static terminal app served at /terminal
      type = lib.types.path;
      default = ./site/terminal;
      description = "The parked terminal app, served under /terminal.";
    };

    hostName = lib.mkOption {          # nginx vhost name (also the default vhost)
      type = lib.types.str;
      default = "carbuncle";
      description = "nginx virtualHost name. Serves as the default vhost.";
    };
  };

  # only applies when the module is enabled: point nginx at the built site.
  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts.${cfg.hostName} = {
        default = true;                       # answer any host/IP that reaches the box
        locations."/" = {
          root = site;                        # serve the immutable store path built above
          extraConfig = "index index.html;";  # use index.html as the directory index
        };
      };
    };
  };
}
