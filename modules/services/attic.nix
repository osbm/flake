{
  config,
  lib,
  ...
}:
{
  options = {
    myModules.enableAttic = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Attic nix cache service";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableAttic {
      services.atticd = {
        enable = true;
        environmentFile = "/persist/attic.env";
        settings = {
          listen = "[::]:5000";
          storage = {
            type = "local";
            path = "/data/atreus/attic";
          };
        };
      };
      networking.firewall.allowedTCPPorts = [ 5000 ];

    })
  ];
}
