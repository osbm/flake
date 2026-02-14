{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Node Exporter Full dashboard - https://grafana.com/grafana/dashboards/1860
  nodeExporterDashboard = pkgs.fetchurl {
    url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
    sha256 = "sha256-1DE1aaanRHHeCOMWDGdOS1YBSaGMNMFPmCPRaQPqd9o=";
    name = "node-exporter-full.json";
  };

  # Loki & Promtail dashboard - https://grafana.com/grafana/dashboards/10880
  lokiDashboard = pkgs.fetchurl {
    url = "https://grafana.com/api/dashboards/10880/revisions/1/download";
    sha256 = "sha256-RgSkOwYvKLetsY+c2LjcJAO9eg+XuFXmMzlJ0JXAdmY=";
    name = "loki-promtail.json";
  };
in
{
  config = lib.mkIf config.osbmModules.services.grafana.enable {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
        };
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:9090";
            isDefault = true;
          }
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://localhost:3100";
          }
        ];
        dashboards.settings.providers = [
          {
            name = "default";
            options.path = "/var/lib/grafana/dashboards";
          }
        ];
      };
    };

    # Copy dashboards into the provisioning directory
    systemd.tmpfiles.rules = [
      "d /var/lib/grafana/dashboards 0755 grafana grafana -"
      "C+ /var/lib/grafana/dashboards/node-exporter-full.json 0644 grafana grafana - ${nodeExporterDashboard}"
      "C+ /var/lib/grafana/dashboards/loki-promtail.json 0644 grafana grafana - ${lokiDashboard}"
    ];

    networking.firewall.allowedTCPPorts = [ 3000 ];
  };
}
