{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./sd-image.nix
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment = "none";
    fonts.enable = false;
    services.tailscale.enable = true;
    hardware.systemd-boot.enable = false; # SD card uses extlinux
  };


  system.stateVersion = "25.05";

  networking.hostName = "harmonica";

  networking = {
    interfaces."wlan0".useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
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
