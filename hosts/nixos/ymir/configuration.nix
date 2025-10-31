{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment = "plasma";
    machineType = "desktop";
    programs = {
      adbFastboot.enable = true;
      steam.enable = true;
    };
    emulation.aarch64.enable = true;
    virtualisation.docker.enable = true;
    hardware = {
      hibernation.enable = false;
      wakeOnLan.enable = true;
      sound.enable = true;
      nvidia.enable = true;
    };
    services = {
      ollama.enable = true;
    };
    i18n.enable = true;
  };

  networking.hostName = "ymir"; # Define your hostname.

  networking.firewall.allowedTCPPorts = [
    8889
    8000
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  virtualisation.waydroid.enable = true;

  system.stateVersion = "25.05"; # changing this is a great taboo of the nixos world
}
