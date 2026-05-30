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

  # agenix deploys ssh-key-private to /home/osbm/.ssh/id_ed25519 and creates the parent
  # /home/osbm/.ssh as root:root in the process. On harmonica's first boot home-manager
  # then tries to write its own files into that directory as user osbm and fails with
  # "Permission denied". Pre-create the dir with the correct ownership so agenix's
  # mkdir -p is a no-op and home-manager can write into it. Scoped to harmonica-sd
  # because that's the only host where systemd-driven home-manager activation actually
  # races with first-boot agenix on a fresh /home; other hosts haven't hit this so we
  # keep the shared agenix module unchanged. If you add another sd-image-style host
  # with home-manager-as-a-systemd-service, copy this rule there too.
  systemd.tmpfiles.rules = [
    "d /home/osbm/.ssh 0700 osbm users -"
  ];

  boot.zfs.forceImportRoot = true;
}
