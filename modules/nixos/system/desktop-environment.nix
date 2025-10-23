{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.osbmModules;
in
{
  config = lib.mkMerge [
    # Plasma Desktop Environment
    (lib.mkIf (cfg.desktopEnvironment == "plasma") {
      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        kate
        konsole
        yakuake
        # kfind ??
      ];

      # Enable printing
      services.printing.enable = true;

      # Enable Bluetooth
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;

      # Desktop packages
      environment.systemPackages = with pkgs; [
        alacritty
        ghostty
        obsidian
        mpv
        kitty
        qbittorrent
        element-desktop
      ];

      # Wayland support
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
    })

    # GNOME Desktop Environment
    (lib.mkIf (cfg.desktopEnvironment == "gnome") {
      services.xserver.enable = true;
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;

      # Enable printing
      services.printing.enable = true;

      # Enable Bluetooth
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;
    })

    # Common settings for any desktop environment
    (lib.mkIf (cfg.desktopEnvironment != "none") {
      # Enable X11 keymap
      services.xserver.xkb = {
        layout = lib.mkDefault "us";
        variant = lib.mkDefault "";
      };
    })
  ];
}
