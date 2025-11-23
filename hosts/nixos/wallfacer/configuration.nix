{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];
  osbmModules = {
    machineType = "server";
    services = {
      hydra.enable = true;
      atticd.enable = true;
      cloudflared.enable = true;
    };
  };

  networking.hostName = "wallfacer";
  system.stateVersion = "25.05";
}
