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
      # kwin 6.8.3 segfaults in InputRedirection::syncTabletWithMouse() when the
      # mouse moves while it is starting up (https://bugs.kde.org/528824).
      # Fixed upstream for 6.8.4; backport the fix until nixpkgs moves on.
      nixpkgs.overlays = [
        (_final: prev: {
          kdePackages = prev.kdePackages.overrideScope (
            _kf: kp: {
              kwin =
                if kp.kwin.version != "6.8.3" then
                  throw ''
                    kwin in nixpkgs is now ${kp.kwin.version}, the bug 528824 backport was written for 6.8.3.
                    Remove the kwin overlay in modules/nixos/system/desktop-environment.nix
                    (the fix ships in 6.8.4), or re-check that it is still needed.
                  ''
                else
                  kp.kwin.overrideAttrs (old: {
                    patches = (old.patches or [ ]) ++ [
                      (prev.fetchpatch {
                        name = "kwin-init-input-backends-after-InputRedirection.patch";
                        url = "https://invent.kde.org/plasma/kwin/-/commit/19404161bc367b87b794361915b85a14c034ec63.patch";
                        hash = "sha256-66OL7ypS/yaK4lMD6sM2E6wVajQ8BkNZy0f6hmPbkLg=";
                      })
                    ];
                  });
            }
          );
        })
      ];

      services = {
        xserver.enable = true;
        displayManager.sddm.enable = true;
        displayManager.sddm.wayland.enable = true;
        desktopManager.plasma6.enable = true;
        printing.enable = true;
        printing.drivers = [
          # L3250 is ESC/P-R v1; escpr2 ships no PPD for it
          pkgs.epson-escpr
          pkgs.epson-escpr2
        ];
        # plasma enables this by default; its udev hook re-runs on every
        # switch, finds the queue already configured and exits 1
        system-config-printer.enable = false;
      };

      # Scanner support (Epson L3250)
      hardware.sane = {
        enable = true;
        extraBackends = [ pkgs.epsonscan2 ];
      };
      users.users.${config.osbmModules.defaultUser}.extraGroups = [
        "scanner"
        "lp"
      ];

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
          mpv
          kitty
          qbittorrent
          anki
          kdePackages.skanpage # scanner app
          # element-desktop # TODO: add another matrix client
          teams-for-linux
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

    # niri desktop environment
    (lib.mkIf cfg.desktopEnvironment.niri.enable {
      # is this it?
      programs.niri.enable = true;
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      environment.systemPackages = with pkgs; [
        awww
        fuzzel
        xhost # needed for running X11 GUI apps with sudo via xwayland-satellite
      ];

      # XWayland satellite service for X11 app support
      systemd.user.services.xwayland-satellite = {
        description = "Xwayland outside Wayland";
        bindsTo = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        environment.DISPLAY = ":0";
        serviceConfig = {
          Type = "notify";
          NotifyAccess = "all";
          ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
          StandardOutput = "journal";
          Restart = "on-failure";
        };
      };
    })

    # Hyprland desktop environment
    (lib.mkIf cfg.desktopEnvironment.hyprland.enable {
      programs.hyprland.enable = true;
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
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
