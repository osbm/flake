{ pkgs, lib, ... }:
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [ pkgs.awww ];

    systemd.user.services.awww = {
      Unit = {
        Description = "Wayland wallpaper daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
