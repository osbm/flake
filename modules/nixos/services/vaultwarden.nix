{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.vaultwarden.enable {
      services.vaultwarden = {
        enable = true;
      };
    })
  ];
}
