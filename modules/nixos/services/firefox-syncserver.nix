{ config, lib, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.firefox-syncserver.enable {
      services.firefox-syncserver = {
        enable = true;
        settings.port = 5000;
      };
    })

    # firefox-syncserver and nginx
    (lib.mkIf
      (config.osbmModules.services.nginx.enable && config.osbmModules.services.firefox-syncserver.enable)
      {
        services.nginx.virtualHosts."firefox.osbm.dev" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.firefox-syncserver.settings.port}";
          };
        };
      }
    )

    # impermanence and firefox-syncserver
    (lib.mkIf
      (
        config.osbmModules.services.firefox-syncserver.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        systemd.services.firefox-syncserver.serviceConfig.ReadWritePaths = [
          "/var/lib/firefox-syncserver"
        ];

        environment.persistence."/persist" = {
          directories = [
            {
              directory = "/var/lib/firefox-syncserver";
              user = config.systemd.services.firefox-syncserver.serviceConfig.User;
              group = config.systemd.services.firefox-syncserver.serviceConfig.Group;
              mode = "0750";
            }
          ];
        };
      }
    )
  ];
}
