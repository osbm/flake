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

    # impermanence with ntfy
    (lib.mkIf
      (
        config.osbmModules.services.ntfy.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
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
      }
    )
  ];
}
