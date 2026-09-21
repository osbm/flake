{
  config,
  lib,
  ...
}:
let
  cfg = config.osbmModules.services.atticd;
  atticdPort = 7080;
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.atticd = {
        enable = true;
        inherit (cfg) environmentFile;
        settings = {
          listen = "[::]:${toString atticdPort}";
          compression = {
            type = "zstd";
            level = 9;
          };
          # drop paths nobody has pulled for 3 months
          garbage-collection.default-retention-period = "3 months";
          # jwt = { };
          # storage = {
          #   type = "local";
          #   # path = "/data/atreus/attic";
          #   # there is an issue
          # };
        }
        // lib.optionalAttrs (cfg.domain != null) {
          # public url, proxied by nginx on apollo (see nginx.nix)
          api-endpoint = "https://${cfg.domain}/";
          allowed-hosts = [
            cfg.domain
            # direct access over tailscale, skips the apollo round trip
            "${config.networking.hostName}.curl-boga.ts.net:${toString atticdPort}"
          ];
        };
      };
      networking.firewall.allowedTCPPorts = [ atticdPort ];
    })
  ];
}
