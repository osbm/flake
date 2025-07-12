{
  config,
  lib,
  ...
}:
{
  options = {
    myModules.enableJellyfin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Jellyfin media server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableJellyfin {
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
