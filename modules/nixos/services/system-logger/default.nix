{
  pkgs,
  config,
  lib,
  ...
}:
let
  system-logger = pkgs.writeShellApplication {
    name = "system-logger";
    runtimeInputs = with pkgs; [
      curl
      jq
      zip
      gawk
      systemd
    ];
    text = builtins.readFile ./system-logger.sh;
  };
in
{
  options.services.system-logger = {
    enable = lib.mkEnableOption {
      description = "Enable System Logger Service";
      default = false;
    };

    logDirectory = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/system-logger";
      description = "Directory to store log archives";
    };

    maxSizeMB = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Maximum size of daily log archive in megabytes";
    };

    retentionDays = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Number of days to retain log archives";
    };
  };

  config = lib.mkIf config.services.system-logger.enable {
    systemd.timers.system-logger = {
      description = "System Logger Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    systemd.services.system-logger = {
      description = "System Logger Service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe system-logger}";
        Restart = "on-failure";
        RestartSec = 60;
        User = "root";
        Group = "root";
      };
    };
  };
}
