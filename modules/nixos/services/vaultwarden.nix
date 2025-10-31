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
        backupDir = "/var/local/vaultwarden/backup";
        # in order to avoid having  ADMIN_TOKEN in the nix store it can be also set with the help of an environment file
        # be aware that this file must be created by hand (or via secrets management like sops)
        environmentFile = config.age.secrets.vaultwarden-env.file;
        config = {
            # Refer to https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
            DOMAIN = "https://bitwarden.osbm.dev";
            SIGNUPS_ALLOWED = false;

            ROCKET_ADDRESS = "127.0.0.1";
            ROCKET_PORT = 8222;
            ROCKET_LOG = "critical";

            # This example assumes a mailserver running on localhost,
            # thus without transport encryption.
            # If you use an external mail server, follow:
            #   https://github.com/dani-garcia/vaultwarden/wiki/SMTP-configuration
            SMTP_HOST = "127.0.0.1";
            SMTP_PORT = 25;
            SMTP_SSL = false;

            SMTP_FROM = "admin@bitwarden.osbm.dev";
            SMTP_FROM_NAME = "osbm.dev Bitwarden server";
        };
      };
    })


    # vaultwarden reverse proxy via nginx
    (lib.mkIf (config.osbmModules.services.nginx.enable && config.osbmModules.services.vaultwarden.enable) {
      services.nginx.virtualHosts."bitwarden.osbm.dev" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}";
        };
      };
    })

    # impermanence with vaultwarden
    (lib.mkIf (config.osbmModules.services.vaultwarden.enable && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot) {
      environment.persistence."/persist" = {
        directories = [
          {
            directory = "/var/lib/vaultwarden";
            user = config.systemd.services.vaultwarden.serviceConfig.User;
            group = config.systemd.services.vaultwarden.serviceConfig.Group;
            mode = "0750";
          }
        ];
      };
    })
  ];
}
    
