{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.osbmModules.services.wanikani-fetch-data;
  wanikani-sync = pkgs.writers.writePython3Bin "wanikani-sync" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./wanikani-sync.py);
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      age.secrets.wanikani-env.file = ../../../../secrets/wanikani-env.age;

      # one hourly job: activity snapshot every run, full daily archive on
      # the first run of each day; :15 offset keeps clear of :00 vault commits
      systemd.timers.wanikani-sync = {
        description = "WaniKani sync";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:15";
        };
      };
      systemd.services.wanikani-sync = {
        description = "WaniKani sync";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe wanikani-sync}";
          EnvironmentFile = config.age.secrets.wanikani-env.path;
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
