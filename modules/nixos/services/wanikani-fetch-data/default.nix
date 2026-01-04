{
  pkgs,
  config,
  lib,
  ...
}:
let
  wanikani-fetcher = pkgs.writeShellApplication {
    name = "wanikani-fetcher";
    runtimeInputs = with pkgs; [
      curl
      jq
      zip
    ];
    text = builtins.readFile ./wanikani-fetcher.sh;
  };
in
{
  config = lib.mkIf config.osbmModules.services.wanikani-fetch-data.enable {
    systemd.timers.wanikani-fetch-data = {
      description = "WaniKani Fetch Data";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "02:00";
      };
    };
    systemd.services.wanikani-fetch-data = {
      description = "WaniKani Fetch Data";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe wanikani-fetcher}";
        Restart = "on-failure";
        RestartSec = 60;
      };
    };
  };
}
