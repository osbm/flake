{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.osbmModules.services.node-exporter.enable {
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = [ "systemd" ];
    };

    networking.firewall.allowedTCPPorts = [ 9100 ];
  };
}
