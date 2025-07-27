{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
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
    enableVaultwarden = true;
  };

  services.wanikani-bypass-lessons.enable = true;
  services.wanikani-fetch-data.enable = true;

  services.glance = {
    enable = true;
    openFirewall = true;
    settings = {
      server = {
        port = 3838;
        host = "0.0.0.0";
      };
      pages = [
        {
          columns = [
            {
              size = "small";
              widgets = [
                {type = "calendar";}
                {
                  type = "repository";
                  repository = "NixOS/nixpkgs";
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "repository";
                  repository = "NixOS/nixpkgs";
                }
                {
                  cache = "1m";
                  sites = [
                    {
                      icon = "si:vaultwarden";
                      title = "Vaultwarden";
                      url = "https://ymir.curl-boga.ts.net:7070/";
                    }
                    # http://ymir.curl-boga.ts.net:4444 ymir remote web vscode
                    {
                      icon = "si:vs-code";
                      title = "Ymir Remote VSCode";
                      url = "https://ymir.curl-boga.ts.net:4444/";
                    }
                  ];
                  title = "Services";
                  type = "monitor";
                }
              ];
            }
          ];
          name = "Home";
          content = "Welcome to Pochita's home page!";
        }
      ];
    };
  };

  # paperless is giving an error
  # services.paperless = {
  #   enable = true;
  # };

  i18n.inputMethod.enable = lib.mkForce false; # no need for japanese input method

  networking.hostName = "pochita";
  # log of shame: osbm blamed nix when he wrote "hostname" instead of "hostName"

  environment.systemPackages = [
    pkgs.raspberrypi-eeprom
  ];

  # The board and wanted kernel version
  raspberry-pi-nix = {
    board = "bcm2712";
    #kernel-version = "v6_10_12";
  };

  system.stateVersion = "25.05";
}
