{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.nginx.enable {
      services.nginx = {
        enable = true;

        # Route [name].sync.osbm.dev -> [name].curl-boga.ts.net:8384
        appendHttpConfig = ''
          server {
            listen 80;
            server_name ~^(?<device>.+)\.sync\.osbm\.dev$;

            location / {
              proxy_pass http://$device.curl-boga.ts.net:8384;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            }
          }
        '';
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];

      security.acme = {
        acceptTerms = true;
        defaults.email = "osbm@osbm.dev";
      };
    })

    (lib.mkIf
      (
        config.osbmModules.services.nginx.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        # environment.persistence."/persist" = {
        #   directories = [
        #     {
        #       directory = "/var/lib/acme";
        #       user = "acme";
        #       group = "nginx";
        #       mode = "0750";
        #     }
        #   ];
        # };
      }
    )
  ];
}
