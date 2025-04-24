{
  lib,
  inputs,
  ...
}: {
  imports = [
    ./sd-image.nix
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ./hardware-configuration.nix
    ../../modules
    inputs.home-manager.nixosModules.home-manager
  ];

  myModules = {
    enableKDE = false;
    enableFonts = false;
    blockYoutube = false;
    blockTwitter = false;
    enableTailscale = true;
  };

  i18n.inputMethod.enable = lib.mkForce false; # no need for japanese input method

  system.stateVersion = "25.05";

  networking.hostName = "harmonica";

  networking = {
    interfaces."wlan0".useDHCP = true;
    wireless = {
      enable = true;
      interfaces = ["wlan0"];
      networks = {
        "House_Bayram" = {
          psk = "PASSWORD";
        };
        "it_hurts_when_IP" = {
          psk = "PASSWORD";
        };
      };
    };
  };

  # NTP time sync.
  services.timesyncd.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  services.getty.autologinUser = "osbm";
}
