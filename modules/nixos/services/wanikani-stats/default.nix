{
  pkgs,
  config,
  lib,
  ...
}:
let
  python =
    # let
    #   packageOverrides = self: super: {
    #     imageio = super.imageio.overridePythonAttrs (old: {
    #       disabledTests = [
    #         "test_read_stream"
    #         "test_uri_reading"
    #         "test_trim_filter"
    #         "test_process_termination"
    #       ];
    #     });
    #     plotly = super.plotly.overridePythonAttrs (old: {
    #       disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [
    #         "tests/test_optional/test_kaleido/test_kaleido.py"
    #       ];
    #     });
    #   };
    # in
    pkgs.python3.override {
      # inherit packageOverrides;
      self = python;
    };
  wanikani-stats-flask = pkgs.writeShellApplication {
    name = "wanikani-stats-flask";
    runtimeInputs = [
      (python.withPackages (
        ppkgs: with ppkgs; [
          flask
          pandas
          plotly
        ]
      ))
    ];
    text = ''
      #!/usr/bin/env bash
      echo "Starting WaniKani Stats Flask app..."
      exec python ${./app.py} ${toString config.osbmModules.services.wanikani-stats.port}
    '';
  };
  cfg = config.osbmModules.services.wanikani-stats;
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;

      systemd = {
        services = {
          wanikani-stats = {
            description = "WaniKani Stats Service";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${lib.getExe wanikani-stats-flask}";
              StateDirectory = "/var/lib/wanikani-stats";
              Restart = "on-failure";
              User = "root";
              Group = "root";
            };
          };

          # Timer to restart the service every 12 hours
          wanikani-stats-restart = {
            description = "Restart WaniKani Stats Service";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.systemd}/bin/systemctl restart wanikani-stats.service";
              User = "root";
            };
          };
        };

        timers.wanikani-stats-restart = {
          description = "Timer to restart WaniKani Stats Service every 12 hours";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 00,12:00:00";
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
        };
      };
    })

    # subdomain behind nginx, tailnet-only (same pattern as hermes.osbm.dev):
    # DNS resolves to apollo's tailnet IP and the vhost rejects non-tailnet
    # sources in case the public IP is hit directly with a matching SNI
    (lib.mkIf (cfg.enable && config.osbmModules.services.nginx.enable) {
      services.nginx.virtualHosts."wanikani-stats.osbm.dev" = {
        forceSSL = true;
        useACMEHost = "osbm.dev";
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          extraConfig = ''
            allow 100.64.0.0/10;
            allow fd7a:115c:a1e0::/48;
            deny all;
          '';
        };
      };
    })
  ];
}
