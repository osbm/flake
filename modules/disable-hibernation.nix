{
  lib,
  config,
  ...
}:
{
  options = {
    myModules.disableHibernation = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable hibernation";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.disableHibernation {
      systemd = {
        targets = {
          sleep = {
            enable = false;
            unitConfig.DefaultDependencies = "no";
          };
          suspend = {
            enable = false;
            unitConfig.DefaultDependencies = "no";
          };
          hibernate = {
            enable = false;
            unitConfig.DefaultDependencies = "no";
          };
          "hybrid-sleep" = {
            enable = false;
            unitConfig.DefaultDependencies = "no";
          };
        };
      };
    })
  ];
}
