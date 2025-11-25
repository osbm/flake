{
  pkgs,
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
    hardware.systemd-boot.enable = false; # Raspberry Pi uses init-script bootloader
    familyUser.enable = true;
    services = {
      wanikani-bypass-lessons.enable = true;
      wanikani-fetch-data.enable = true;
      wanikani-stats.enable = true;
    };
    desktopEnvironment.plasma.enable = true;
    programs.graphical.enable = false;
  };

  zramSwap.enable = true;

  networking.hostName = "pochita";
  # log of shame: osbm blamed nix when he wrote "hostname" instead of "hostName"

  environment.systemPackages = [
    pkgs.raspberrypi-eeprom
  ];

  # The board and wanted kernel version
  raspberry-pi-nix = {
    board = "bcm2712";
    libcamera-overlay.enable = false;
    #kernel-version = "v6_10_12";
  };

  system.stateVersion = "25.05";
}
