{ config, lib, ... }:

let
  cfg = config.services.spellboundSite;
in
{
  options.services.spellboundSite = {
    enable = lib.mkEnableOption "the Spellbound terminal website";

    root = lib.mkOption {
      type = lib.types.path;
      default = ./site;
      description = "Static site source tree served by nginx.";
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
        locations."/".root = cfg.root;
      };
    };
  };
}
