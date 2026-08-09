{ config, lib, pkgs, ... }:

let
  cfg = config.services.spellboundSite;

  blog = pkgs.runCommand "spellbound-blog"
    { nativeBuildInputs = with pkgs; [ cmark-gfm coreutils gnused gawk bash ]; }
    ''
      bash ${./blog-generate.sh} ${cfg.blogSrc} $out
      mkdir -p $out/fonts
      cp ${cfg.loraFont}/share/fonts/truetype/'Lora[wght].ttf' $out/fonts/Lora.ttf
      cp ${cfg.loraFont}/share/fonts/truetype/'Lora-Italic[wght].ttf' $out/fonts/Lora-Italic.ttf
    '';

  site = pkgs.runCommand "spellbound-site" { } ''
    mkdir -p $out
    cp -r ${blog}/. $out/
    cp -r ${cfg.terminalSrc} $out/terminal
  '';
in
{
  options.services.spellboundSite = {
    enable = lib.mkEnableOption "the spellbound.sh blog";

    blogSrc = lib.mkOption {
      type = lib.types.path;
      default = ./site/blog;
      description = "Markdown + template sources for the blog.";
    };

    loraFont = lib.mkOption {
      type = lib.types.package;
      default = pkgs.lora;
      description = "The Lora font package, served under /fonts.";
    };

    terminalSrc = lib.mkOption {
      type = lib.types.path;
      default = ./site/terminal;
      description = "The parked terminal app, served under /terminal.";
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "carbuncle";
      description = "nginx virtualHost name. Serves as the default vhost.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts.${cfg.hostName} = {
        default = true;
        locations."/" = {
          root = site;
          extraConfig = "index index.html;";
        };
      };
    };
  };
}
