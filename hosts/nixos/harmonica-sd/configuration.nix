{
  config,
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
    fonts.enable = false;
    services.tailscale.enable = true;
    hardware.systemd-boot.enable = false; # SD card uses extlinux
  };

  system.stateVersion = "25.05";

  networking.hostName = "harmonica";

  age.secrets.harmonica-wifi-env = {
    file = ../../../secrets/harmonica-wifi-env.age;
    owner = "wpa_supplicant";
    group = "wpa_supplicant";
  };

  networking = {
    interfaces."wlan0".useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
      secretsFile = config.age.secrets.harmonica-wifi-env.path;
      networks = {
        "House_Bayram".pskRaw = "ext:HOUSE_BAYRAM_PSK";
        # TODO: add "it_hurts_when_IP" back here (and its PSK var in harmonica-wifi-env.age)
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

  boot.zfs.forceImportRoot = true;
}
