{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];
  osbmModules = {
    desktopEnvironment = "none";
    machineType = "server";
    services.nextcloud.enable = true;
    services.hydra.enable = true;
    # services.caddy.enable = true;
    services.attic.enable = true;
    services.cloudflared.enable = true;
  };

  i18n.inputMethod.enable = lib.mkForce false;
  networking.hostName = "wallfacer";
  system.stateVersion = "25.05";
}
