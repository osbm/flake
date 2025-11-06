{ config, lib, pkgs, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.firefox-syncserver.enable {
      services.mysql.package = pkgs.mariadb; # Use MariaDB as the database backend
      services.firefox-syncserver = {
        enable = true;
        secrets = "/persist/firefox-syncserver-secrets.env"; # TODO: Make this into agenix secret
        logLevel = "trace";
        singleNode = {
          enable = true;
          url = "https://firefox.osbm.dev";
          capacity = 1;
        };
        settings = {
          host = "0.0.0.0";
          # Override database URLs to use Unix socket for authentication
          # This allows the firefox-syncserver user to authenticate via unix_socket
          syncstorage.database_url = "mysql://firefox-syncserver@localhost/firefox_syncserver?socket=%2Frun%2Fmysqld%2Fmysqld.sock";
          tokenserver.database_url = "mysql://firefox-syncserver@localhost/firefox_syncserver?socket=%2Frun%2Fmysqld%2Fmysqld.sock";
        };
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
