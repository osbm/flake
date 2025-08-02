{
  pkgs,
  config,
  lib,
  ...
}:
let
  wanikani-stats-flask = pkgs.writeShellApplication {
    name = "wanikani-stats-flask";
    runtimeInputs = [
      (pkgs.python312.withPackages (
        ppkgs: with pkgs.python312Packages; [
          flask
          pandas
          numpy
          jinja2
          matplotlib
          seaborn
        ]
      ))
    ];
    text = ''
      #!/usr/bin/env bash
      echo "Starting WaniKani Stats Flask app..."
      exec python ${./app.py} ${toString config.services.wanikani-stats.port}
    '';
  };
in
{
  options.services.wanikani-stats = {
    enable = lib.mkEnableOption {
      description = "Enable WaniKani Stats Service";
      default = false;
    };

    logDirectory = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/wanikani-logs";
      description = "Directory to get the log archives";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8501;
      description = "Port for the WaniKani Stats service";
    };
  };

  config = lib.mkIf config.services.wanikani-stats.enable {
    networking.firewall.allowedTCPPorts = [
      config.services.wanikani-stats.port
    ];

    systemd.services.wanikani-stats = {
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
    systemd.services.wanikani-stats-restart = {
      description = "Restart WaniKani Stats Service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart wanikani-stats.service";
        User = "root";
      };
    };

    systemd.timers.wanikani-stats-restart = {
      description = "Timer to restart WaniKani Stats Service every 12 hours";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 00,12:00:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
