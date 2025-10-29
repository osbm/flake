{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment = "plasma";
    machineType = "laptop";
    emulation.aarch64.enable = true;
    hardware.sound.enable = true;
    programs.steam.enable = true;
  };

  networking.hostName = "tartarus"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  system.stateVersion = "24.05"; # lalalalala
}
