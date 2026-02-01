{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];
  osbmModules = {
    services = {
      # hydra.enable = true;
      atticd.enable = true;
      syncthing.enable = true;

      # Backup client - pulls full backup from apollo
      backup-client = {
        enable = true;
        backups = {
          apollo-full = {
            remoteHost = "apollo"; # Tailscale hostname
            localPath = "/var/backups/apollo";
            fullBackup = true;
          };
        };
      };
    };
  };

  networking.hostName = "wallfacer";
  system.stateVersion = "25.05";
}
