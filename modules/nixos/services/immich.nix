{ config, lib, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.immich.enable {
      services.immich = {
        enable = true;
      };
    })

    # immich and nginx
    (lib.mkIf (config.osbmModules.services.nginx.enable && config.osbmModules.services.immich.enable) {
      services.nginx.virtualHosts."immich.osbm.dev" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.immich.port}";
          proxyWebsockets = true;
        };
      };
    })

    # impermanence and immich
    (lib.mkIf
      (
        config.osbmModules.services.immich.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        environment.persistence."/persist" = {
          directories = [
            {
              directory = "/var/lib/immich";
              user = config.services.immich.user;
              group = config.services.immich.group;
              mode = "0750";
            }
          ];
        };
      }
    )
  ];
}
