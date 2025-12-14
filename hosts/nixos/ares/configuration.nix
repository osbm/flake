{
  imports = [
    # ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment = {
      plasma.enable = true;
    };
    familyUser.enable = true;
    programs = {
      adbFastboot.enable = true;
      steam.enable = true;
    };
    hardware = {
      hibernation.enable = false;
      sound.enable = true;
    };
    i18n.enable = true;
  };

  networking = {
    hostName = "ares";

    firewall.allowedTCPPorts = [
      8889
      8000
    ];

    networkmanager.enable = true;
  };

  virtualisation.waydroid.enable = true;

  system.stateVersion = "26.05"; # changing this is a great taboo of the nixos world
}
