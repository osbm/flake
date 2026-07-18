{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  # hermes CLI for `hermes desktop` — the GUI connects in remote mode to the
  # gateway on apollo (https://hermes.osbm.dev); no local hermes service here
  environment.systemPackages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  osbmModules = {
    desktopEnvironment = {
      plasma.enable = true;
      niri.enable = true;
      # hyprland.enable = true; # im insane so i enable every DE
    };
    familyUser.enable = true;
    programs = {
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
      syncthing.enable = true;

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

  # services.displayManager.autoLogin = {
  #   enable = true;
  #   user = "osbm";
  # };

  # virtualisation.waydroid.enable = true;

  system.stateVersion = "25.05"; # changing this is a great taboo of the nixos world
}
