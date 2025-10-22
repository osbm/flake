{ lib, nixosConfig, ... }:
{
  config = lib.mkMerge [
    (lib.mkIf (nixosConfig != null && nixosConfig.osbmModules.desktopEnvironment != "none") {
      programs.mpv.enable = lib.mkDefault true;
    })

    {
      programs.mpv = {
        config = {
          hwdec = "auto";
          vo = "gpu";
        };
      };
    }

  ];
}
