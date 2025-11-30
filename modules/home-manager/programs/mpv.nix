{ lib, nixosConfig, ... }:
{
  config = lib.mkMerge [
    (lib.mkIf (nixosConfig != null && !nixosConfig.osbmModules.desktopEnvironment.none) {
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

    # Raspberry Pi 5 specific: Use OpenGL to avoid Vulkan memory issues
    (lib.mkIf (nixosConfig != null && nixosConfig.networking.hostName == "pochita") {
      programs.mpv.config.gpu-api = "opengl";
    })

  ];
}
