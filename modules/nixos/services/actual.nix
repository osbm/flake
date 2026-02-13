{ config, lib, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.actual.enable {
      services.actual = {
        enable = true;
        settings = {
          port = 51514;
        };
      };

      # disable DynamicUser, use a static user instead
      users.users.actual = {
        isSystemUser = true;
        group = "actual";
        home = "/var/lib/actual";
      };
      users.groups.actual = { };

      systemd.services.actual.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "actual";
        Group = "actual";
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

    # impermanence with actual
    (lib.mkIf
      (
        config.osbmModules.services.actual.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        environment.persistence."/persist" = {
          directories = [
            {
              directory = "/var/lib/actual";
              user = "actual";
              group = "actual";
              mode = "0750";
            }
          ];
        };
      }
    )
  ];
}
