{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
    inputs.vscode-server.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  myModules = {
    enableKDE = false;
    enableFonts = false;
    blockYoutube = false;
    blockTwitter = false;
    enableForgejo = true;
    # enableCaddy = true;
    # enableCloudflareDyndns = true;
    enableCloudflared = true;
  };

  i18n.inputMethod.enable = lib.mkForce false; # no need for japanese input method

  networking.hostName = "pochita";
  # log of shame: osbm blamed nix when he wrote "hostname" instead of "hostName"

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.osbm = import ../../home/home.nix {
    inherit config pkgs;
    backupFileExtension = "hmbak";
  };

  environment.systemPackages = [
    pkgs.raspberrypi-eeprom
  ];

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  security.acme.defaults = {
    email = "osmanfbayram@gmail.com";
    acceptTerms = true;
  };

  services.getty.autologinUser = "osbm";

  # The board and wanted kernel version
  raspberry-pi-nix = {
    board = "bcm2712";
    #kernel-version = "v6_10_12";
  };

  system.stateVersion = "25.05";
}
