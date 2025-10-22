{
  config,
  lib,
  ...
}:
let
  atticdPort = 7080;
in
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.atticd.enable {
      services.atticd = {
        enable = true;
        environmentFile = "/persist/attic.env";
        settings = {
          listen = "[::]:${toString atticdPort}";
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
      networking.firewall.allowedTCPPorts = [ atticdPort ];
      services.cloudflared.tunnels = {
        "fa301a21-b259-4149-b3d0-b1438c7c81f8" = {
          default = "http_status:404";
          credentialsFile = "/home/osbm/.cloudflared/fa301a21-b259-4149-b3d0-b1438c7c81f8.json";
          ingress = {
            "cache.osbm.dev" = {
              service = "http://localhost:${toString atticdPort}";
            };
          };
        };
      };
    })
  ];
}
