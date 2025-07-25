{
  lib,
  config,
  ...
}:
{
  options = {
    myModules.enableForgejo = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Forgejo server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableForgejo {
      services.forgejo = {
        enable = true;
        lfs.enable = true;
        dump = {
          enable = true;
          type = "zip";
          interval = "01:01";
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
        };
      };
    })
  ];
}
