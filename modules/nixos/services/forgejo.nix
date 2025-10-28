{
  lib,
  config,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.forgejo.enable {
      services.forgejo = {
        enable = true;
        lfs.enable = true;
        dump = {
          enable = true;
          type = "zip";
          interval = "01:01";
        };
        settings = {
          DEFAULT = {
            APP_NAME = "osbm's self hosted git service";
          };
          server = {
            DOMAIN = "git.osbm.dev";
            ROOT_URL = "https://git.osbm.dev/";
          };
          "ui.meta" = {
            AUTHOR = "osbm";
            DESCRIPTION = "\"After all, all devices have their dangers. The discovery of speech introduced communication and lies.\" -Isaac Asimov";
            KEYWORDS = "git,self-hosted,gitea,forgejo,osbm,open-source,nix,nixos";
          };
          service = {
            DISABLE_REGISTRATION = true;
            LANDING_PAGE = "/osbm";
          };
        };
      };
    })

    (lib.mkIf
      (config.osbmModules.services.cloudflared.enable && config.osbmModules.services.forgejo.enable)
      {
        services.cloudflared.tunnels = {
          "eb9052aa-9867-482f-80e3-97a7d7e2ef04" = {
            default = "http_status:404";
            credentialsFile = "/home/osbm/.cloudflared/eb9052aa-9867-482f-80e3-97a7d7e2ef04.json";
            ingress = {
              "${config.services.forgejo.settings.server.DOMAIN}" = {
                service = "http://localhost:3000";
              };
            };
          };
        };
      }
    )
    (lib.mkIf (config.osbmModules.services.nginx.enable && config.osbmModules.services.forgejo.enable) {
      services.nginx.virtualHosts."${config.services.forgejo.settings.server.DOMAIN}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://localhost:3000";
        locations."/".proxyWebsockets = true;
      };
    })

    (lib.mkIf
      (
        config.osbmModules.services.forgejo.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        environment.persistence."/persist" = {
          hideMounts = true;
          directories = [
            "/var/lib/forgejo"
          ];
        };
      }
    )
  ];
}
