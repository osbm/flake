{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];
  osbmModules = {
    desktopEnvironment = "none";
    machineType = "server";
    services = {
      nextcloud.enable = true;
      hydra.enable = true;
      # caddy.enable = true;
      atticd.enable = true;
      cloudflared.enable = true;
    };
  };

  networking.hostName = "wallfacer";
  system.stateVersion = "25.05";
}
