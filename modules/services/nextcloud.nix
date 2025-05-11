{
  lib,
  config,
  pkgs,
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
      environment.etc."nextcloud-admin-pass".text = "m7eJ4KJ1NK33JE%51";
      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud31;
        hostName = "localhost";
        config.adminpassFile = "/etc/nextcloud-admin-pass";
        config.dbtype = "sqlite";
      };
    })
  ];
}
