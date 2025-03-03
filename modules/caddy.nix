{pkgs, lib, config, ...}: {

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
          plugins = ["github.com/caddy-dns/cloudflare@v0.0.0-20250228175314-1fb64108d4de"];
          hash = "sha256-3nvVGW+ZHLxQxc1VCc/oTzCLZPBKgw4mhn+O3IoyiSs=";
        };
        email = "contact@osbm.dev";
        extraConfig = ''
          (cloudflare) {
              tls {
                dns cloudflare {env.CLOUDFLARE_API_TOKEN}
              }
            }
        '';
      };

      networking.firewall.allowedTCPPorts = [80 443 3000];

      environment.systemPackages = with pkgs; [
        nssTools
      ];

      systemd.services.caddy.serviceConfig = {
        LoadCredential = "CLOUDFLARE_API_TOKEN:${config.age.secrets.cloudflare.path}";
        EnvironmentFile = "-%t/caddy/secrets.env";
        RuntimeDirectory = "caddy";
        ExecStartPre = [
          ((pkgs.writeShellApplication {
              name = "caddy-secrets";
              text = "echo \"CLOUDFLARE_API_TOKEN=\\\"$(<\"$CREDENTIALS_DIRECTORY/CLOUDFLARE_API_TOKEN\")\\\"\" > \"$RUNTIME_DIRECTORY/secrets.env\"";
            })
            + "/bin/caddy-secrets")
        ];
        AmbientCapabilities = "cap_net_bind_service";
        CapabilityBoundingSet = "cap_net_bind_service";
      };
    })
  ];
}
