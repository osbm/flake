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
    (lib.mkIf cfg.desktopEnvironment.plasma.enable {
      services = {
        xserver.enable = true;
        displayManager.sddm.enable = true;
        desktopManager.plasma6.enable = true;
        printing.enable = true;
      };

      environment = {
        plasma6.excludePackages = with pkgs.kdePackages; [
          kate
          konsole
          yakuake
          krunner # fuckass program keeps opening
        ];
        systemPackages = with pkgs; [
          alacritty
          ghostty
          obsidian
          mpv
          kitty
          qbittorrent
          anki
          # element-desktop # TODO: add another matrix client
        ];
        sessionVariables.NIXOS_OZONE_WL = "1";
      };
    })

    # GNOME Desktop Environment
    (lib.mkIf cfg.desktopEnvironment.gnome.enable {

      # Enable GNOME Desktop Environment
      services = {
        xserver.enable = true;
        desktopManager.gnome.enable = true;
        displayManager.gdm.enable = true;
        gnome.gnome-keyring.enable = true;
      };

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
    (lib.mkIf (!cfg.desktopEnvironment.none) {
      # Enable X11 keymap
      services.xserver.xkb = {
        layout = lib.mkDefault "us";
        variant = lib.mkDefault "";
      };
    })
  ];
}
