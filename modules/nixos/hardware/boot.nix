{ config, lib, ... }:

{
  config = lib.mkIf config.osbmModules.hardware.systemd-boot.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
