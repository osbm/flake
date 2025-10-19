{
  config,
  lib,
  ...
}:
{
  options = {
    osbmModules.enableVaultwarden = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Vaultwarden server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.enableVaultwarden {
      services.vaultwarden = {
        enable = true;
      };
    })
  ];
}
