{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.cloudflare-dyndns.enable {
      services.cloudflare-dyndns = {
        enable = true;
        apiTokenFile = "/persist/cloudflare-dyndns";
        proxied = false; # TODO please revert
        domains = [
          "git.osbm.dev"
          "aifred.osbm.dev"
        ];
      };
    })
  ];
}
