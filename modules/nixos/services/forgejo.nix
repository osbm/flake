{
  lib,
  config,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.forgejo.enable {
      services.forgejo = {
        enable = true;
        lfs.enable = true;
        secrets.mailer.PASSWD = config.age.secrets."forgejo-mail".path;
        dump = {
          enable = true;
          type = "zip";
          interval = "01:01";
          age = "1w";
        };
        settings = {
          DEFAULT = {
            APP_NAME = "osbm's self hosted git service";
          };
          server = {
            DOMAIN = "git.osbm.dev";
            ROOT_URL = "https://git.osbm.dev/";
          };
          "ui.meta" = {
            AUTHOR = "osbm";
            DESCRIPTION = "\"After all, all devices have their dangers. The discovery of speech introduced communication and lies.\" -Isaac Asimov";
            KEYWORDS = "git,self-hosted,gitea,forgejo,osbm,open-source,nix,nixos";
          };
          service = {
            DISABLE_REGISTRATION = true;
            LANDING_PAGE = "/osbm";
          };
          other = {
            SHOW_FOOTER_VERSION = false;
            SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
            ENABLE_FEED = false;
          };
          mailer = {
            ENABLED = true;
            PROTOCOL = "smtps";
            SMTP_ADDR = "osbm.dev";
            USER = "forgejo@osbm.dev";
          };
        };
      };
    })

    (lib.mkIf (config.osbmModules.services.nginx.enable && config.osbmModules.services.forgejo.enable) {
      services.nginx.virtualHosts."${config.services.forgejo.settings.server.DOMAIN}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://localhost:3000";
        locations."/".proxyWebsockets = true;
      };
    })

    (lib.mkIf
      (
        config.osbmModules.services.forgejo.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        # environment.persistence."/persist" = {
        #   directories = [
        #     {
        #       directory = "/var/lib/forgejo";
        #       user = config.services.forgejo.user;
        #       group = config.services.forgejo.group;
        #       mode = "0750";
        #     }
        #   ];
        # };

        # # forgejo-secrets service keep giving error
        # systemd.services."forgejo-secrets" = {
        #   wants = [ "var-lib-forgejo.mount" ];
        #   after = [ "var-lib-forgejo.mount" ];
        # };

        # fuckass thing
        services.forgejo.stateDir = "/persist/var/lib/forgejo";
      }
    )
  ];
}
