{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment = "plasma";
    emulation.aarch64.enable = true;
    hardware.sound.enable = true;
  };

  networking.hostName = "tartarus"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  system.stateVersion = "24.05"; # lalalalala
}
