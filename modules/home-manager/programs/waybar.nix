{
  lib,
  pkgs,
  nixosConfig,
  ...
}:
{
  config = lib.mkMerge [
    # Auto-enable Waybar only for niri and hyprland (not for Plasma/GNOME which have their own panels)
    # systemd.enable is false because niri launches waybar via its own config
    (lib.mkIf (
      pkgs.stdenv.isLinux
      && nixosConfig != null
      && (nixosConfig.osbmModules.desktopEnvironment.niri.enable || nixosConfig.osbmModules.desktopEnvironment.hyprland.enable)
    ) {
      programs.waybar = {
        enable = lib.mkDefault true;
        systemd.enable = false;
      };
    })
  ];
}
