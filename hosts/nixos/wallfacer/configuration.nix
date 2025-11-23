{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];
  osbmModules = {
    services = {
      hydra.enable = true;
      atticd.enable = true;
      cloudflared.enable = true;
    };
  };

  networking.hostName = "wallfacer";
  system.stateVersion = "25.05";
}
