{ lib, config, ... }:
{
  config = lib.mkIf config.osbmModules.hardware.sound.enable {
    # Disable PulseAudio
    services.pulseaudio.enable = false;

    # Enable rtkit for realtime audio
    security.rtkit.enable = true;

    # Enable PipeWire
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications:
      # jack.enable = true;
    };
  };
}
