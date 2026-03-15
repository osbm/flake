{
  config,
  lib,
  inputs,
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

    # Automatically write the flake revision and commit timestamp to the
    # textfile metrics directory on boot / nixos-rebuild switch.
    system.activationScripts.exportNixosRevision = ''
            mkdir -p /var/lib/node-exporter
            REV="${config.system.configurationRevision or "unknown"}"
            TIMESTAMP="${toString (inputs.self.lastModified or 0)}"
            REVCOUNT="${toString (inputs.self.revCount or 0)}"
            cat > /var/lib/node-exporter/revision.prom.tmp <<PROM
      node_nixos_configuration_revision{revision="$REV"} 1
      node_nixos_configuration_timestamp{revision="$REV"} $TIMESTAMP
      node_nixos_configuration_revcount{revision="$REV"} $REVCOUNT
      PROM
            mv /var/lib/node-exporter/revision.prom.tmp /var/lib/node-exporter/revision.prom
    '';

    networking.firewall.allowedTCPPorts = [ 9100 ];
  };
}
