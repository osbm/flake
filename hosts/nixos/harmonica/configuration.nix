{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    enableKDE = false;
    enableFonts = false;
  };

  i18n.inputMethod.enable = lib.mkForce false; # no need for japanese input method

  system.stateVersion = "25.05";

  networking.hostName = "harmonica";

  # NTP time sync.
  services.timesyncd.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  # services.getty.autologinUser = "osbm";
}
