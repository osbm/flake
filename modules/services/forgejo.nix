{
  lib,
  config,
  ...
}: {
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
        };
        settings = {
          server = {
            DOMAIN = "git.osbm.dev";
            ROOT_URL = "https://git.osbm.dev/";
          };
          service = {
            DISABLE_REGISTRATION = true;
            LANDING_PAGE = "osbm";
          };
        };
      };
    })
  ];
}
