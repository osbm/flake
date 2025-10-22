{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.hydra.enable {
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
