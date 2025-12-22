{
  lib,
  pkgs,
  nixosConfig,
  ...
}:
{
  config = lib.mkMerge [
    # Auto-enable Waybar only if system has a desktop environment and is Linux
    (lib.mkIf (pkgs.stdenv.isLinux && nixosConfig != null && !nixosConfig.osbmModules.desktopEnvironment.none) {
      programs.waybar = {
        enable = lib.mkDefault true;
        systemd.enable = true;
      };
    })
  ];
}
