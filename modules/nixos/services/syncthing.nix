{
  config,
  lib,
  ...
}:
{
  options = {
    osbmModules.enableSyncthing = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Syncthing file synchronization service";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.enableSyncthing {
      services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        # port is 8384
      };
    })
  ];
}
