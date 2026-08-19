{ config, lib, pkgs, ... }:

let
  cfg = config.services.spellboundSite;

  # the served tree (blog at root + terminal at /terminal), built by the shared
  # expression so dev builds on shiva match what deploys to carbuncle exactly
  site = import ./site-pkg.nix {
    inherit pkgs;
    blogSrc = cfg.blogSrc;
    terminalSrc = cfg.terminalSrc;
    loraFont = cfg.loraFont;
    hackFont = cfg.hackFont;
  };
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

    hackFont = lib.mkOption {          # monospace for code blocks + terminal
      type = lib.types.package;
      default = pkgs.hack-font;
      description = "The Hack font package, served under /fonts (code + terminal).";
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
