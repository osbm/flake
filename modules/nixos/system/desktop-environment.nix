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

      # Enable GNOME Desktop Environment
      services.xserver.enable = true;
      services.desktopManager.gnome.enable = true;
      services.displayManager.gdm.enable = true;

      # Enable GNOME Keyring for password management
      services.gnome.gnome-keyring.enable = true;

      # Enable dconf for GNOME settings
      programs.dconf.enable = true;

      # Remove unwanted GNOME applications
      environment.gnome.excludePackages = with pkgs; [
        baobab # disk usage analyzer
        cheese # photo booth
        eog # image viewer
        epiphany # web browser
        simple-scan # document scanner
        totem # video player
        yelp # help viewer
        evince # document viewer
        file-roller # archive manager
        geary # email client
        seahorse # password manager
        gnome-calculator
        gnome-calendar
        gnome-characters
        gnome-clocks
        gnome-contacts
        gnome-font-viewer
        gnome-logs
        gnome-maps
        gnome-music
        gnome-screenshot
        gnome-system-monitor
        gnome-weather
        gnome-disk-utility
        pkgs.gnome-connections
      ];

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
