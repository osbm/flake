{
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    fonts.enable = false;
    services.tailscale.enable = true;
    hardware.systemd-boot.enable = false;
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
      };
    };
  };

  services.timesyncd.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  services.getty.autologinUser = "osbm";

  # Same agenix/home-manager race as harmonica-sd: pre-create /home/osbm/.ssh as
  # osbm:users so agenix's mkdir doesn't pin it to root and break home-manager.
  systemd.tmpfiles.rules = [
    "d /home/osbm/.ssh 0700 osbm users -"
  ];

  boot.zfs.forceImportRoot = true;
}
