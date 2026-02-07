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

        # Catch-all default server: return 404 for unknown subdomains
        virtualHosts."_" = {
          default = true;
          rejectSSL = false;
          sslCertificate = "/var/lib/acme/sync.osbm.dev/fullchain.pem";
          sslCertificateKey = "/var/lib/acme/sync.osbm.dev/key.pem";
          locations."/".return = "404";
        };

        # Route [name].sync.osbm.dev -> [name].curl-boga.ts.net:8384
        appendHttpConfig = ''
          server {
            listen 80;
            listen 443 ssl;
            server_name ~^(?<device>.+)\.sync\.osbm\.dev$;

            ssl_certificate /var/lib/acme/sync.osbm.dev/fullchain.pem;
            ssl_certificate_key /var/lib/acme/sync.osbm.dev/key.pem;

            resolver 100.100.100.100;

            location / {
              set $backend http://$device.curl-boga.ts.net:8384;
              proxy_pass $backend;
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
        certs."sync.osbm.dev" = {
          domain = "*.sync.osbm.dev";
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          credentialFiles = {
            "CF_DNS_API_TOKEN_FILE" = config.age.secrets.cloudflare-apollo-zone-dns-edit.path;
          };
          group = "nginx";
        };
        certs."osbm.dev" = {
          domain = "*.osbm.dev";
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          credentialFiles = {
            "CF_DNS_API_TOKEN_FILE" = config.age.secrets.cloudflare-apollo-zone-dns-edit.path;
          };
          group = "nginx";
        };
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
