{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];
  myModules = {
    enableKDE = false;
    enableFonts = false;
    enableNextcloud = true;
  };

  services.hydra = {
    enable = true;
    hydraURL = "http://localhost:54543";
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [];
    useSubstitutes = true;
  };
  networking.firewall.allowedTCPPorts = [ 54543 ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  i18n.inputMethod.enable = lib.mkForce false;
  networking.hostName = "wallfacer";
  system.stateVersion = "25.05";
}
