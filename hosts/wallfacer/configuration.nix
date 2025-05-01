{
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];
  myModules = {
    enableKDE = false;
    enableFonts = false;
  };
  i18n.inputMethod.enable = lib.mkForce false;
  networking.hostName = "wallfacer";
  environment.systemPackages = [
  ];

  services.getty.autologinUser = "osbm";
  system.stateVersion = "25.05";
}
