{lib, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];
  myModules = {
    enableKDE = false;
    enableFonts = false;
    enableNextcloud = true;
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  i18n.inputMethod.enable = lib.mkForce false;
  networking.hostName = "wallfacer";
  # services.getty.autologinUser = "osbm";
  system.stateVersion = "25.05";
}
