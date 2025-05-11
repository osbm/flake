{
  lib,
  config,
  ...
}: {
  options = {
    myModules.enableNextcloud = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Nextcloud server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableNextcloud {
      services.nextcloud = {
        enable = true;
      };
    })
  ];
}
