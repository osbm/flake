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
    desktopEnvironment = "none";
    machineType = "server";
    hardware.systemd-boot.enable = false;  # Raspberry Pi uses init-script bootloader
    services = {
      forgejo.enable = true;
      cloudflared.enable = true;
      vaultwarden.enable = true;
      glance.enable = true;
      wanikani-bypass-lessons.enable = true;
      wanikani-fetch-data.enable = true;
      wanikani-stats.enable = true;
    };
  };

  zramSwap.enable = true;

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
