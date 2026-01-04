{
  pkgs,
  config,
  lib,
  ...
}:
let
  wakeup-ymir = pkgs.writeShellApplication {
    name = "wakeup-ymir";
    runtimeInputs = with pkgs; [
      wakeonlan
    ];
    text = builtins.readFile ./wakeup-ymir.sh;
  };
in
{
  options.services.wakeup-ymir.enable = lib.mkEnableOption {
    description = "Enable Wake-up Ymir Timer";
    default = config.osbmModules.services.wakeup-ymir.enable or false;
  };

  config = lib.mkIf config.services.wakeup-ymir.enable {
    systemd.timers.wakeup-ymir = {
      description = "Wake up Ymir at 6 AM";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "06:00";
        Persistent = true;
      };
    };
    systemd.services.wakeup-ymir = {
      description = "Send Wake-on-LAN packet to Ymir";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe wakeup-ymir}";
        Restart = "on-failure";
        RestartSec = 60;
      };
    };
  };
}
