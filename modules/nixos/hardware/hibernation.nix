{ lib, config, ... }:
{
  config = lib.mkIf (!config.osbmModules.hardware.hibernation.enable) {
    # Disable hibernation/suspend
    systemd.targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };
}
