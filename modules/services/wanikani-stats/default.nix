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
              matplotlib
              pandas
              numpy
              seaborn
            ]
        )
      )
    ];
    text = ''
      #!/usr/bin/env bash
      echo "Starting WaniKani Stats Streamlit app..."
      exec streamlit run ${./app.py} \
        --server.port ${toString config.services.wanikani-stats.port} \
        --browser.gatherUsageStats false
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
    # systemd.timers.wanikani-stats = {
    #   description = "WaniKani Stats Timer";
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnCalendar = "daily";
    #     Persistent = true;
    #   };
    # };
    networking.firewall.allowedTCPPorts = [
      config.services.wanikani-stats.port
    ];

    systemd.services.wanikani-stats = {
      description = "WaniKani Stats Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe wanikani-stats-streamlit}";
        StateDirectory = "/var/lib/wanikani-stats";
        Restart = "on-failure";
        User = "root";
        Group = "root";
      };
    };
  };
}
