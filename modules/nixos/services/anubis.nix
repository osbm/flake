{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.anubis.enable {
      services.anubis = {
        # enable = true;
      };
    })
  ];
}