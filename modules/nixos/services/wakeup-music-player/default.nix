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
  options.services.wakeup-music-player = {
    enable = lib.mkEnableOption {
      description = "Enable Wakeup Music Player";
      default = config.osbmModules.services.wakeup-music-player.enable or false;
    };

    musicFile = lib.mkOption {
      type = lib.types.path;
      default = "/home/osbm/Music/wakeup.mp3";
      description = "Path to the music file to play on wakeup";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "osbm";
      description = "User to run the music player as";
    };
  };

  config = lib.mkIf config.services.wakeup-music-player.enable {
    systemd.services.wakeup-music-player = {
      description = "Play Wakeup Music";
      after = [
        "display-manager.service"
        "sound.target"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe wakeup-music-player} ${config.services.wakeup-music-player.musicFile} ${config.services.wakeup-music-player.user}";
        User = config.services.wakeup-music-player.user;
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
