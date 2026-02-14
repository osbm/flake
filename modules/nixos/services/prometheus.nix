{
  config,
  lib,
  ...
}:
let
  cfg = config.osbmModules.services.prometheus;
  machines = [
    "apollo"
    "ares"
    "artemis"
    "harmonica"
    "pochita"
    "tartarus"
    "wallfacer"
    "ymir"
  ];
  targets = map (m: "${m}.curl-boga.ts.net:9100") machines;
in
{
  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      port = 9090;
      listenAddress = "0.0.0.0";

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              inherit targets;
            }
          ];
          scrape_interval = "15s";
        }
      ];

      alertmanagers = [
        {
          static_configs = [
            {
              targets = [ "localhost:9093" ];
            }
          ];
        }
      ];

      rules = [
        (builtins.toJSON {
          groups = [
            {
              name = "machine-health";
              rules = [
                {
                  alert = "MachineDown";
                  expr = "up == 0";
                  "for" = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "{{ $labels.instance }} is down";
                    description = "{{ $labels.instance }} has been unreachable for more than 5 minutes.";
                  };
                }
              ];
            }
          ];
        })
      ];
    };

    services.prometheus.alertmanager = {
      enable = true;
      port = 9093;
      listenAddress = "0.0.0.0";
      configuration = {
        route = {
          receiver = "ntfy";
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
        };
        receivers = [
          {
            name = "ntfy";
            webhook_configs = [
              {
                url = "http://localhost:2586/alerts";
                send_resolved = true;
              }
            ];
          }
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      9090
      9093
    ];
  };
}
