{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment.plasma.enable = true;
    familyUser.enable = true;
    emulation.aarch64.enable = true;
    hardware.sound.enable = true;
    programs.steam.enable = true;
  };

  networking.hostName = "tartarus"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  system.stateVersion = "24.05"; # lalalalala
}
