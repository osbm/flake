{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment.plasma.enable = true;
    familyUser.enable = true;
    emulation.aarch64.enable = true;
    hardware.sound.enable = true;
    programs.steam.enable = true;

    services = {
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
  };

  networking.hostName = "tartarus";

  # Enable networking
  networking.networkmanager.enable = true;

  system.stateVersion = "24.05"; # lalalalala
}
