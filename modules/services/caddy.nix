{
  pkgs,
  lib,
  config,
  ...
}:
{
  options = {
    myModules.enableCaddy = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Caddy server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableCaddy {
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          # update time to time
          # last update: 2025-03-02
          plugins = [ "github.com/caddy-dns/cloudflare@v0.0.0-20250228175314-1fb64108d4de" ];
          hash = "sha256-x5SJSns16VaqOyKLCtaMIMWaooT+C0f9iSWKFBTywnA=";
        };
        email = "osbm@osbm.dev";
        extraConfig = ''
          (cloudflare) {
            tls {
              dns cloudflare {env.CF_API_TOKEN}
            }
          }
        '';
        # globalConfig = ''
        #   acme_dns cloudflare {env.CF_API_TOKEN}
        # '';
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
        3000
      ];

      environment.systemPackages = with pkgs; [
        nssTools
      ];
      age.secrets.cloudflare = {
        file = ../../secrets/cloudflare.age;
        path = "/etc/caddy/.env";
        owner = "caddy";
        mode = "0600";
      };

      systemd.services.caddy.serviceConfig = {
        EnvironmentFile = "/etc/caddy/.env";
      };

      security.acme.acceptTerms = true;
      security.acme.defaults = {
        email = "osbm@osbm.dev";
        acceptTerms = true;
      };

    })
  ];
}
