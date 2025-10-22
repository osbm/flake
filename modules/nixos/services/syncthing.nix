{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.syncthing.enable {
      services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        # port is 8384
      };
    })
  ];
}
