{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.jellyfin.enable {
      services.jellyfin = {
        enable = true;
        openFirewall = true;
        user = "osbm";
        group = "users";
        dataDir = "/home/osbm/.local/share/jellyfin";
      };

      networking.firewall.allowedTCPPorts = [ 8096 ];
    })
  ];
}
