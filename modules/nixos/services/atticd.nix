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
    })
  ];
}
