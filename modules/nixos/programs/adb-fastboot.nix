{ lib, config, ... }:
{
  config = lib.mkIf config.osbmModules.programs.adbFastboot.enable {
    programs.adb.enable = true;

    # Add default user to adbusers group
    users.users.${config.osbmModules.defaultUser}.extraGroups = [ "adbusers" ];
  };
}
