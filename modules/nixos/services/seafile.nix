{ config, lib, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.seafile.enable {
      services.seafile = {
        enable = true;
        adminEmail = "osbm@osbm.dev";
        initialAdminPassword = "changeme";
        seafileSettings = {
          fileserver = {
            host = "unix:/run/seafile/server.sock";
          };
        };
      };
    })

    # seafile and nginx
    (lib.mkIf (config.osbmModules.services.nginx.enable && config.osbmModules.services.seafile.enable) {
      services.nginx.virtualHosts."seafile.osbm.dev" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://unix:/run/seahub/gunicorn.sock";
            extraConfig = ''
              proxy_set_header   Host $host;
              proxy_set_header   X-Real-IP $remote_addr;
              proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header   X-Forwarded-Host $server_name;
              proxy_read_timeout  1200s;
              client_max_body_size 0;
            '';
          };
          "/seafhttp" = {
            proxyPass = "http://unix:/run/seafile/server.sock";
            extraConfig = ''
              rewrite ^/seafhttp(.*)$ $1 break;
              client_max_body_size 0;
              proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_connect_timeout  36000s;
              proxy_read_timeout  36000s;
              proxy_send_timeout  36000s;
              send_timeout  36000s;
            '';
          };
        };
      };
    })

    # impermanence and seafile
    (lib.mkIf
      (
        config.osbmModules.services.seafile.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        environment.persistence."/persist" = {
          directories = [
            {
              directory = "/var/lib/seafile";
              user = config.services.seafile.user;
              group = config.services.seafile.group;
              mode = "0750";
            }
          ];
        };
      }
    )
  ];
}
