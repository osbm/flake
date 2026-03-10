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
      enabledCollectors = [
        "systemd"
        "textfile"
      ];
      extraFlags = [
        "--collector.textfile.directory=/var/lib/node-exporter"
      ];
    };

    # Automatically write the flake revision to the textfile metrics directory
    # whenever the system boots or `nixos-rebuild switch` is run.
    system.activationScripts.exportNixosRevision = ''
      mkdir -p /var/lib/node-exporter
      REV="${config.system.configurationRevision or "unknown"}"
      echo "node_nixos_configuration_revision{revision=\"$REV\"} 1" > /var/lib/node-exporter/revision.prom.tmp
      mv /var/lib/node-exporter/revision.prom.tmp /var/lib/node-exporter/revision.prom
    '';

    networking.firewall.allowedTCPPorts = [ 9100 ];
  };
}
