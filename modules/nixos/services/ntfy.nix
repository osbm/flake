{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.ntfy.enable {
      services.ntfy-sh = {
        enable = true;
        settings = {
          base-url = "https://ntfy.osbm.dev";
          listen-http = ":2586";
          behind-proxy = true;
        };
      };
    })

    # ntfy reverse proxy via nginx
    (lib.mkIf
      (config.osbmModules.services.nginx.enable && config.osbmModules.services.ntfy.enable)
      {
        services.nginx.virtualHosts."ntfy.osbm.dev" = {
          forceSSL = true;
          useACMEHost = "osbm.dev";
          locations."/" = {
            proxyPass = "http://localhost:2586";
            proxyWebsockets = true;
          };
        };
      }
    )

    # impermanence: ntfy-sh data lives in /var/lib/private/ntfy-sh (DynamicUser),
    # persisted via /var/lib/private in base impermanence config
  ];
}
