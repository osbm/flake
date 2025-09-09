{lib, ...}:
{
  options = {
    myModules.enableKDE = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable KDE Plasma";
    };
  };
}