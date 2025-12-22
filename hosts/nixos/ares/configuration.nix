{ inputs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
    inputs.jovian-nixos.nixosModules.default
  ];

  osbmModules = {
    desktopEnvironment = {
      plasma.enable = true;
    };
    familyUser.enable = true;
    programs = {
      steam.enable = true;
    };
    hardware = {
      # hibernation.enable = false;
      sound.enable = true;
    };
    i18n.enable = true;
  };

  jovian = {
    devices.steamdeck = {
      enable = true;
      autoUpdate = true;
    };
    steam = {
      enable = true;
      autoStart = true;
      user = "osbm";
      desktopSession = "plasma";
    };
    decky-loader.enable = true;
  };

  # Disable SDDM since Jovian manages its own display manager
  services.displayManager.sddm.enable = lib.mkForce false;

  networking = {
    hostName = "ares";

    firewall.allowedTCPPorts = [
      8889
      8000
    ];

    networkmanager.enable = true;
  };

  system.stateVersion = "26.05"; # changing this is a great taboo of the nixos world
}
