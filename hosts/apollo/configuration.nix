{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  myModules = {
    enableKDE = false;
    enableFonts = false;
    blockYoutube = false;
    blockTwitter = false;
  };

  i18n.inputMethod.enable = lib.mkForce false; # no need for japanese input method
  system.stateVersion = "25.05";
  networking.hostName = "apollo";
}
