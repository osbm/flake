{
  config,
  lib,
  ...
}:
{
  options = {
    myModules.enableSyncthing = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Syncthing file synchronization service";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableSyncthing {
      services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        # port is 8384
      };
    })
  ];
}
