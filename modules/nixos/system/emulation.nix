{ lib, config, ... }:
{
  config = lib.mkIf config.osbmModules.emulation.aarch64.enable {
    # Enable binfmt for aarch64 emulation
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
