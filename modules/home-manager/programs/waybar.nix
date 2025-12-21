{
  lib,
  nixosConfig,
  ...
}:
{
  config = lib.mkMerge [
    # Auto-enable Waybar only if system has a desktop environment
    (lib.mkIf (nixosConfig != null && !nixosConfig.osbmModules.desktopEnvironment.none) {
      programs.waybar = {
        enable = lib.mkDefault true;
        systemd.enable = true;
      };
    })
  ];
}
