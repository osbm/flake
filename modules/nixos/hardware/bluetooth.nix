{ config, lib, ... }:
{
  config = lib.mkIf config.osbmModules.hardware.bluetooth.enable {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
  };
}