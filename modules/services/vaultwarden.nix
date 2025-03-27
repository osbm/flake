{
  config,
  lib,
  ...
}: {
  options = {
    myModules.enableVaultwarden = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Vaultwarden server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableVaultwarden {
      services.vaultwarden.enable = true;
    })
  ];
}
