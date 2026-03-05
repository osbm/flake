{
  config,
  lib,
  pkgs,
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

  # Tiny webhook relay that reformats Alertmanager JSON into casual ntfy messages
  ntfyRelay = pkgs.writeScript "ntfy-relay" ''
    #!${pkgs.python3}/bin/python3
    from http.server import HTTPServer, BaseHTTPRequestHandler
    import json, urllib.request

    class Handler(BaseHTTPRequestHandler):
        def do_POST(self):
            data = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            for alert in data.get("alerts", []):
                instance = alert.get("labels", {}).get("instance", "unknown")
                name = instance.split(".")[0]
                status = alert.get("status", "unknown")
                if status == "firing":
                    msg = f"{name} just went dark"
                    priority = "urgent"
                    tags = "skull"
                else:
                    msg = f"{name} is back up"
                    priority = "default"
                    tags = "white_check_mark"
                req = urllib.request.Request(
                    "http://localhost:2586/alerts",
                    data=msg.encode(),
                    headers={"Title": msg, "Priority": priority, "Tags": tags},
                )
                try:
                    urllib.request.urlopen(req)
                except Exception as e:
                    print(f"Failed to send to ntfy: {e}")
            self.send_response(200)
            self.end_headers()

        def log_message(self, format, *args):
            print(format % args)

    HTTPServer.allow_reuse_address = True
    HTTPServer(("127.0.0.1", 9096), Handler).serve_forever()
  '';
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
                  "for" = "1m";
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

    # Webhook relay: Alertmanager -> casual message -> ntfy
    systemd.services.ntfy-relay = {
      description = "Alertmanager to ntfy relay";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = ntfyRelay;
        Restart = "always";
        DynamicUser = true;
      };
    };

    services.prometheus.alertmanager = {
      enable = true;
      port = 9093;
      listenAddress = "0.0.0.0";
      configuration = {
        route = {
          receiver = "ntfy";
          group_by = [ "instance" ];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "7d";
        };
        receivers = [
          {
            name = "ntfy";
            webhook_configs = [
              {
                url = "http://localhost:9096";
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
