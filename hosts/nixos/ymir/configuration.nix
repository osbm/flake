{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment = {
      # plasma.enable = true;
      niri.enable = true;
      # hyprland.enable = true; # im insane so i enable every DE
    };
    familyUser.enable = true;
    programs = {
      adbFastboot.enable = true;
      steam.enable = true;
    };
    emulation.aarch64.enable = true;
    virtualisation.docker.enable = true;
    hardware = {
      hibernation.enable = false;
      wakeOnLan.enable = true;
      sound.enable = true;
      nvidia.enable = true;
    };
    services = {
      ollama.enable = true;

      # Backup client - pulls vaultwarden backup from apollo
      backup-client = {
        enable = true;
        backups = {
          apollo-vaultwarden = {
            remoteHost = "apollo";
            localPath = "/var/backups/apollo-vaultwarden";
            services = [ "vaultwarden" ];
          };
        };
      };
    };
    i18n.enable = true;
  };

  networking = {
    hostName = "ymir";

    firewall.allowedTCPPorts = [
      8889
      8000
    ];

    networkmanager.enable = true;
  };

  virtualisation.waydroid.enable = true;

  system.stateVersion = "25.05"; # changing this is a great taboo of the nixos world
}
