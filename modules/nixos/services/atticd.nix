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
          # the server hands api-endpoint to every client and `attic push`
          # switches to it for uploads regardless of the endpoint it logged in
          # with. keep that the direct tailnet address, otherwise a push from
          # the same LAN (or from a github runner whose ACL only reaches this
          # port) detours through nginx on apollo.
          api-endpoint = "http://${config.networking.hostName}.curl-boga.ts.net:${toString atticdPort}/";
          # what `attic use` writes as the nix substituter: the public https
          # url, proxied by nginx on apollo (see nginx.nix)
          substituter-endpoint = "https://${cfg.domain}/";
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
