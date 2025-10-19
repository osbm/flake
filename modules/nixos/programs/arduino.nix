{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.osbmModules.programs.arduino.enable {
    environment.systemPackages = with pkgs; [
      arduino-ide
      adafruit-nrfutil
      python3 # some arduino libraries require python3
    ];

    services.udev.extraRules = ''
      KERNEL=="ttyUSB[0-9]*",MODE="0666"
      KERNEL=="ttyACM[0-9]*",MODE="0666"
    '';
  };
}
