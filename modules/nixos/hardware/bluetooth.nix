{ config, lib, ... }:
{
  config = lib.mkIf config.hardware.bluetooth.enable {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
  };
}