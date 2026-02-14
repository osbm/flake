{
  config,
  lib,
  ...
}:
let
  cfg = config.osbmModules.services.ntfy;
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.ntfy-sh = {
        enable = true;
        settings = {
          base-url = cfg.baseUrl;
          listen-http = ":2586";
          behind-proxy = cfg.behindProxy;
        };
      };

      # disable DynamicUser, use a static user instead
      users.users.ntfy-sh = {
        isSystemUser = true;
        group = "ntfy-sh";
        home = "/var/lib/ntfy-sh";
      };
      users.groups.ntfy-sh = { };

      systemd.services.ntfy-sh.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "ntfy-sh";
        Group = "ntfy-sh";
      };
    })

    # When not behind a proxy, open the firewall port directly
    (lib.mkIf (cfg.enable && !cfg.behindProxy) {
      networking.firewall.allowedTCPPorts = [ 2586 ];
    })

    # ntfy reverse proxy via nginx
    (lib.mkIf (config.osbmModules.services.nginx.enable && cfg.enable) {
      services.nginx.virtualHosts."ntfy.osbm.dev" = {
        forceSSL = true;
        useACMEHost = "osbm.dev";
        locations."/" = {
          proxyPass = "http://localhost:2586";
          proxyWebsockets = true;
        };
      };
    })

    # impermanence with ntfy
    (lib.mkIf (cfg.enable && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot) {
      environment.persistence."/persist" = {
        directories = [
          {
            directory = "/var/lib/ntfy-sh";
            user = "ntfy-sh";
            group = "ntfy-sh";
            mode = "0750";
          }
        ];
      };
    })
  ];
}
