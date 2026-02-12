{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.radicale.enable {
      services.radicale = {
        enable = true;
        settings = {
          server = {
            hosts = [ "127.0.0.1:5232" ];
          };
          auth = {
            type = "htpasswd";
            htpasswd_filename = "/var/lib/radicale/htpasswd";
            htpasswd_encryption = "bcrypt";
          };
          storage = {
            filesystem_folder = "/var/lib/radicale/collections";
          };
        };
      };
    })

    # radicale reverse proxy via nginx
    (lib.mkIf
      (config.osbmModules.services.nginx.enable && config.osbmModules.services.radicale.enable)
      {
        services.nginx.virtualHosts."cal.osbm.dev" = {
          forceSSL = true;
          useACMEHost = "osbm.dev";
          locations."/" = {
            proxyPass = "http://localhost:5232";
            extraConfig = ''
              proxy_set_header X-Script-Name /;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header Host $host;
            '';
          };
        };
      }
    )

    # impermanence with radicale
    (lib.mkIf
      (
        config.osbmModules.services.radicale.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        environment.persistence."/persist" = {
          directories = [
            {
              directory = "/var/lib/radicale";
              user = "radicale";
              group = "radicale";
              mode = "0750";
            }
          ];
        };
      }
    )
  ];
}
