{
  pkgs,
  config,
  lib,
  ...
}:
let
  wakeup-music-player = pkgs.writeShellApplication {
    name = "wakeup-music-player";
    runtimeInputs = with pkgs; [
      mpv
      coreutils
    ];
    text = builtins.readFile ./wakeup-music-player.sh;
  };
in
{
  config = lib.mkIf config.osbmModules.services.wakeup-music-player.enable {
    systemd.services.wakeup-music-player = {
      description = "Play Wakeup Music";
      after = [
        "display-manager.service"
        "sound.target"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe wakeup-music-player} ${config.osbmModules.services.wakeup-music-player.musicFile} ${config.osbmModules.services.wakeup-music-player.user}";
        User = config.osbmModules.services.wakeup-music-player.user;
        Environment = [
          "XDG_RUNTIME_DIR=/run/user/1000"
          "PULSE_RUNTIME_PATH=/run/user/1000/pulse"
        ];
        # Don't restart - just play once on boot
        RemainAfterExit = false;
      };
    };
  };
}
