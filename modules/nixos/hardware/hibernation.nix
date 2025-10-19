{ lib, config, ... }:
{
  config = lib.mkIf (!config.osbmModules.hardware.hibernation.enable) {
    # Disable hibernation/suspend
    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;
  };
}
