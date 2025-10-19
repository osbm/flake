{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
  ];

  osbmModules = {
    enableKDE = false;
    enableFonts = false;
    enableForgejo = true;
    # enableCaddy = true;
    # enableCloudflareDyndns = true;
    enableCloudflared = true;
    enableVaultwarden = true;
    enableGlance = true;
  };

  services.wanikani-bypass-lessons.enable = true;
  services.wanikani-fetch-data.enable = true;
  services.wanikani-stats.enable = true;

  # paperless is giving an error
  # services.paperless = {
  #   enable = true;
  # };

  i18n.inputMethod.enable = lib.mkForce false; # no need for japanese input method

  networking.hostName = "pochita";
  # log of shame: osbm blamed nix when he wrote "hostname" instead of "hostName"

  environment.systemPackages = [
    pkgs.raspberrypi-eeprom
  ];

  # The board and wanted kernel version
  raspberry-pi-nix = {
    board = "bcm2712";
    #kernel-version = "v6_10_12";
  };

  system.stateVersion = "25.05";
}
