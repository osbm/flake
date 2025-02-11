{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    inputs.vscode-server.nixosModules.default
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  myModules = {
    blockYoutube = false;
    blockTwitter = true;
    blockBluesky = false;
    enableKDE = true;
    enableTailscale = true;
    enableAarch64Emulation = true;
    enableSound = true;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.osbm = import ../../home/home.nix {
    inherit config pkgs;
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

  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.x86_64-linux.default
    inputs.osbm-nvim.packages.x86_64-linux.default
  ];

  system.stateVersion = "24.05"; # lalalalala
}
