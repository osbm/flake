{ config, lib, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.paperless.enable {
      services.paperless = {
        enable = true;
        port = 28981;
        settings.PAPERLESS_URL = "https://paperless.osbm.dev";
      };
    })

    # paperless and nginx
    (lib.mkIf (config.osbmModules.services.nginx.enable && config.osbmModules.services.paperless.enable)
      {
        services.nginx.virtualHosts."paperless.osbm.dev" = {
          forceSSL = true;
          useACMEHost = "osbm.dev";
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.paperless.port}";
            proxyWebsockets = true;
          };
        };
      }
    )

    # impermanence with paperless
    (lib.mkIf
      (
        config.osbmModules.services.paperless.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        environment.persistence."/persist" = {
          directories = [
            {
              directory = "/var/lib/paperless";
              user = "paperless";
              group = "paperless";
              mode = "0750";
            }
          ];
        };
      }
    )
  ];
}
