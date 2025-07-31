{
  pkgs,
  config,
  lib,
  ...
}:
let
  wanikani-stats-streamlit = pkgs.writeShellApplication {
    name = "wanikani-stats-streamlit";
    runtimeInputs = [
      (pkgs.python312.withPackages (
          ppkgs:
            with pkgs.python312Packages; [
              pip
              streamlit
            ]
        )
      )
    ];
    text = ''
      #!/usr/bin/env bash
      exec streamlit run /path/to/your/wanikani_stats_app.py
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
  };

  config = lib.mkIf config.services.wanikani-stats.enable {
    # systemd.timers.wanikani-stats = {
    #   description = "WaniKani Stats Timer";
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnCalendar = "daily";
    #     Persistent = true;
    #   };
    # };

    systemd.services.wanikani-stats = {
      description = "WaniKani Stats Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe wanikani-stats-streamlit}";
        Restart = "always";
        RestartSec = 60;
        User = "root";
        Group = "root";
      };
    };
  };
}
