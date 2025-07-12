{
  lib,
  config,
  ...
}:
{
  options = {
    myModules.enableAarch64Emulation = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Aarch64 emulation";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableAarch64Emulation {
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      nix.settings.extra-platforms = config.boot.binfmt.emulatedSystems;
    })
  ];
}
