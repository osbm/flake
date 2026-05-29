{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
  ];

  osbmModules = {
    hardware.systemd-boot.enable = false; # Raspberry Pi uses init-script bootloader
    familyUser.enable = true;
    services = {
      wanikani-bypass-lessons.enable = true;
      wanikani-fetch-data.enable = true;
      wanikani-stats.enable = true;
      syncthing.enable = true;

      # Monitoring stack
      ntfy = {
        enable = true;
        baseUrl = "http://pochita.curl-boga.ts.net:2586";
        behindProxy = false;
      };
      healthcheck = {
        enable = true;
        target = "http://apollo.curl-boga.ts.net:9100/metrics";
      };
      loki.enable = true;
      grafana.enable = true;
      # Backup client - pulls full backup from apollo
      backup-client = {
        enable = true;
        backups = {
          apollo-full = {
            remoteHost = "apollo"; # Tailscale hostname
            localPath = "/var/backups/apollo";
            fullBackup = true;
          };
        };
      };
    };
    # desktopEnvironment.plasma.enable = true;
    programs.graphical.enable = false;
  };

  # systemd-in-initrd hangs waiting for NVMe by-partuuid device on Pi 5; legacy script initrd works
  boot.initrd.systemd.enable = false;

  # load in initrd, else stage-2 races the /boot/firmware mount and drops to emergency mode
  boot.initrd.kernelModules = [
    "nls_cp437"
    "nls_iso8859-1"
  ];

  zramSwap.enable = true;

  networking.hostName = "pochita";
  networking.networkmanager.enable = true;

  # log of shame: osbm blamed nix when he wrote "hostname" instead of "hostName"

  environment.systemPackages = [
    pkgs.raspberrypi-eeprom
  ];

  # The board and wanted kernel version
  raspberry-pi-nix = {
    board = "bcm2712";
    libcamera-overlay.enable = false;
    #kernel-version = "v6_10_12";
  };

  system.stateVersion = "25.05";
}
