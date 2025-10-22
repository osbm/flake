{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.nextcloud.enable {
      environment.etc."nextcloud-admin-pass".text = "m7eJ4KJ1NK33JE%51";
      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud31;
        hostName = "localhost/nextcloud";
        config.adminpassFile = "/etc/nextcloud-admin-pass";
        config.dbtype = "sqlite";
        database.createLocally = true;
        settings.trusted_domains = [
          "${config.networking.hostName}.curl-boga.ts.net"
          "localhost"
        ];
      };
    })
  ];
}
