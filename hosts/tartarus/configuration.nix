{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  myModules = {
    blockYoutube = false;
    blockTwitter = true;
    blockBluesky = false;
    enableKDE = true;
    enableAarch64Emulation = true;
    enableSound = true;
  };

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = ["osbm"];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tartarus"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  system.stateVersion = "24.05"; # lalalalala
}
