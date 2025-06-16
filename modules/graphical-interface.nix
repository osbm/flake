{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    myModules.enableKDE = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable KDE Plasma Desktop Environment with my favorite packages";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableKDE {
      # Enable the X11 windowing system.
      # You can disable this if you're only using the Wayland session.
      services.xserver.enable = true;

      # Enable the KDE Plasma Desktop Environment.
      services.displayManager.sddm = {
        enable = true;
        # theme = "sugar-dark"; # looks ugly i give up
        # wayland.enable = true;
      };
      services.desktopManager.plasma6.enable = true;

      environment.plasma6.excludePackages = [
        pkgs.kdePackages.kate
        pkgs.kdePackages.konsole
      ];

      # Enable CUPS to print documents.
      services.printing.enable = true;

      hardware.bluetooth.enable = true; # enables support for Bluetooth
      hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
      environment.systemPackages = with pkgs; [
        blender
        inkscape
        sddm-sugar-dark
        screenkey
        vscode
        alacritty
        ghostty
        obsidian
        mpv
        pomodoro-gtk
        libreoffice
        gimp
        kitty
        obs-studio
        audacity
        qbittorrent
        ani-cli
        prismlauncher
        element-desktop
        qbittorrent
        discord
        (pkgs.writeShellApplication {
          name = "sync-terraria";
          runtimeInputs = [
            pkgs.python3Packages.huggingface-hub
            pkgs.zip
          ];
          text = ''
            # check if logged in to huggingface
            if [ "$(huggingface-cli whoami)" == "Not logged in" ]; then
              echo "Please log in to huggingface"
              exit 1
            fi

            cd ~/.local/share
            timestamp=$(date +%Y-%m-%d_%H-%M)
            echo "$timestamp"
            zip -r "Terraria_$timestamp.zip" Terraria/
            huggingface-cli upload --repo-type dataset osbm/terraria-backups "Terraria_$timestamp.zip" "Terraria_$timestamp.zip"
          '';
        })
      ];

      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      programs.steam = {
        enable = true;
        # Open ports in the firewall for Steam Remote Play
        remotePlay.openFirewall = true;
        # Open ports in the firewall for Source Dedicated Server
        dedicatedServer.openFirewall = true;
        # Open ports in the firewall for Steam Local Network Game Transfers
        localNetworkGameTransfers.openFirewall = true;
      };
      networking.firewall.allowedTCPPorts = [51513];
    })
  ];
}
