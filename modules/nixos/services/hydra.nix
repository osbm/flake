{
  config,
  lib,
  ...
}:
{
  options = {
    osbmModules.enableHydra = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Hydra continuous integration server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.enableHydra {
      services.hydra = {
        enable = true;
        port = 3000;
        hydraURL = "http://${config.networking.hostName}.curl-boga.ts.net/hydra/";
        notificationSender = "hydra@localhost";
        buildMachinesFiles = [ ];
        useSubstitutes = true;
      };
      networking.firewall.allowedTCPPorts = [
        config.services.hydra.port
      ];
    })
  ];
}
