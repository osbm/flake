{
  lib,
  config,
  ...
}:
{
  options = {
    myModules.enableSound = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable sound with pipewire.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableFonts {
      # Enable sound with pipewire.
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    })
  ];
}
