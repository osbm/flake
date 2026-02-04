{ config, lib, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.actual.enable {
      services.actual = {
        enable = true;
        settings = {
          port = 51514;

          # dataDir = "/var/lib/actual"
        };
      };
    })

    # actual and nginx
    (lib.mkIf (config.osbmModules.services.nginx.enable && config.osbmModules.services.actual.enable) {
      services.nginx.virtualHosts."actual.osbm.dev" = {
        forceSSL = true;
        useACMEHost = "osbm.dev";
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.actual.settings.port}";
          proxyWebsockets = true;
        };
      };
    })

    # # impermanence and immich
    # (lib.mkIf
    #   (
    #     config.osbmModules.services.immich.enable
    #     && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
    #   )
    #   {
    #     environment.persistence."/persist" = {
    #       directories = [
    #         {
    #           directory = "/var/lib/immich";
    #           user = config.services.immich.user;
    #           group = config.services.immich.group;
    #           mode = "0750";
    #         }
    #         {
    #           directory = "/var/lib/postgresql";
    #           user = "postgres";
    #           group = "postgres";
    #           mode = "0750";
    #         }
    #       ];
    #     };
    #   }
    # )
  ];
}
