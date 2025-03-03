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
          settings = {
            server = {
              DOMAIN = "git.osbm.dev";
              ROOT_URL = "https://git.osbm.dev/";
            };
            service = {
              DISABLE_REGISTRATION = false;
            };
          };
        };
    })
    # if enableForgejo and enableCaddy are enabled, add forgejo to caddy
    (lib.mkIf (config.myModules.enableForgejo && config.myModules.enableCaddy) {
      services.caddy.virtualHosts."git.osbm.dev" = {
        extraConfig = ''
          reverse_proxy pochita.curl-boga.ts.net:3000
        '';
      };
    })
  ];
}
