{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.osbmModules.services.wanikani-fetch-data;
  wanikani-fetcher = pkgs.writeShellApplication {
    name = "wanikani-fetcher";
    runtimeInputs = with pkgs; [
      curl
      jq
    ];
    text = builtins.readFile ./wanikani-fetcher.sh;
  };
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      age.secrets.wanikani-env.file = ../../../../secrets/wanikani-env.age;

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
          EnvironmentFile = config.age.secrets.wanikani-env.path;
          Restart = "on-failure";
          RestartSec = 60;
        };
      };
    })

    # keep the archive across reboots on impermanent-root hosts
    (lib.mkIf (cfg.enable && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot) {
      environment.persistence."/persist" = {
        directories = [ "/var/lib/wanikani-logs" ];
      };
    })
  ];
}
