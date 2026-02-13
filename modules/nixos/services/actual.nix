{ config, lib, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.actual.enable {
      services.actual = {
        enable = true;
        settings = {
          port = 51514;

          # dataDir = "/var/lib/actual"
        };
      };
    })

    # actual and nginx
    (lib.mkIf (config.osbmModules.services.nginx.enable && config.osbmModules.services.actual.enable) {
      services.nginx.virtualHosts."actual.osbm.dev" = {
        forceSSL = true;
        useACMEHost = "osbm.dev";
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.actual.settings.port}";
          proxyWebsockets = true;
        };
      };
    })

    # impermanence: actual data lives in /var/lib/private/actual (DynamicUser),
    # persisted via /var/lib/private in base impermanence config
  ];
}
