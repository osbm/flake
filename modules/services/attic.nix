{
  config,
  lib,
  ...
}:
{
  options = {
    myModules.enableAttic = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Attic nix cache service";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableAttic {
      services.atticd = {
        enable = true;
        environmentFile = "/persist/attic.env";
        settings = {
          listen = "[::]:5000";
          allowedHosts = [
            "cache.osbm.dev"
            "wallfacer.curl-boga.ts.net"
            "localhost"
            "wallfacer"
          ];
          jwt = { };
          # storage = {
          #   type = "local";
          #   # path = "/data/atreus/attic";
          #   # there is an issue
          # };
        };
      };
      networking.firewall.allowedTCPPorts = [ 5000 ];
      services.cloudflared.tunnels = {
        "fa301a21-b259-4149-b3d0-b1438c7c81f8" = {
          default = "http_status:404";
          credentialsFile = "/home/osbm/.cloudflared/fa301a21-b259-4149-b3d0-b1438c7c81f8.json";
          ingress = {
            "cache.osbm.dev" = {
              service = "http://localhost:5000";
            };
          };
        };
      };
    })
  ];
}
