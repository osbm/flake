{ lib, config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules
  ];
  osbmModules = {
    enableKDE = false;
    enableFonts = false;
    enableNextcloud = true;
    enableHydra = true;
    # enableCaddy = true;
    enableAttic = true;
    enableCloudflared = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  i18n.inputMethod.enable = lib.mkForce false;
  networking.hostName = "wallfacer";
  system.stateVersion = "25.05";
}
