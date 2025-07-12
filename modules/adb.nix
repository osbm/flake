{
  lib,
  config,
  ...
}:
{
  options = {
    myModules.enableADB = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ADB support";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableADB {
      programs.adb.enable = true;
      users.users.osbm.extraGroups = [ "adbusers" ];
    })
  ];
}
