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
  config = lib.mkIf config.osbmModules.services.system-logger.enable {
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
