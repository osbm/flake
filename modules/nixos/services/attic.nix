{
  config,
  lib,
  ...
}:
let
  atticPort = 7080;
in
{
  options = {
    osbmModules.enableAttic = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Attic nix cache service";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.enableAttic {
      services.atticd = {
        enable = true;
        environmentFile = "/persist/attic.env";
        settings = {
          listen = "[::]:${toString atticPort}";
          compression = {
            type = "zstd";
            level = 9;
          };
          # jwt = { };
          # storage = {
          #   type = "local";
          #   # path = "/data/atreus/attic";
          #   # there is an issue
          # };
        };
      };
      networking.firewall.allowedTCPPorts = [ atticPort ];
      services.cloudflared.tunnels = {
        "fa301a21-b259-4149-b3d0-b1438c7c81f8" = {
          default = "http_status:404";
          credentialsFile = "/home/osbm/.cloudflared/fa301a21-b259-4149-b3d0-b1438c7c81f8.json";
          ingress = {
            "cache.osbm.dev" = {
              service = "http://localhost:${toString atticPort}";
            };
          };
        };
      };
    })
  ];
}
