{pkgs, config, lib, ...}:
let
  wanikani-fetcher = pkgs.writeShellApplication {
    name = "wanikani-fetcher";
    runtimeInputs = with pkgs; [curl jq zip];
    # read script from the wanikani-fetcher.sh file
    text = builtins.readFile ./wanikani-fetcher.sh;
  };
in  {
  options.services.wanikani-fetch-data.enable = lib.mkEnableOption {
    description = "Enable WaniKani Fetch Data";
    default = false;
  };

  config = lib.mkIf config.services.wanikani-fetch-data.enable {

    systemd.timers.wanikani-fetch-data = {
      description = "WaniKani Fetch Data";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
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
