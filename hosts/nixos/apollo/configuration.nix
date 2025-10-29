{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment = "none";
    machineType = "server";
    users = [ "osbm" ];
    services = {
      glance.enable = true;
      # anubis.enable = true;
      nginx.enable = true;
      # forgejo.enable = true;
    };

    hardware = {
      sound.enable = false;
      hibernation.enable = false;

      disko = {
        enable = true;
        fileSystem = "zfs";

        initrd-ssh = {
          enable = true;
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k"
          ];
          ethernetDrivers = [
            "virtio_pci" # QEMU support
            "virtio_net"
            "virtio_pci"
            "virtio_blk"
            "virtio_balloon"
            "virtio_console"
            "virtio_gpu"
          ];
        };

        zfs = {
          enable = true;
          hostID = "0f7de22e";
          root = {
            useTmpfs = false; # Use ZFS root, not tmpfs
            encrypt = true;
            disk1 = "vda";
            impermanenceRoot = true; # Wipe root on boot with ZFS snapshots
          };
        };
      };
    };
  };

  system.stateVersion = "25.11";
  networking.hostName = "apollo";

  # Enable zram swap
  zramSwap.enable = true;

  users.mutableUsers = false;

  # Disable sudo lecture message
  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';

  # Network configuration
  networking = {
    useDHCP = false;
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "152.53.152.129";
          prefixLength = 22;
        }
      ];
      ipv6.addresses = [
        {
          address = "2a00:11c0:47:3b2a::1";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway = "152.53.152.1";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ]; # Cloudflare and Google DNS
  };

  # Override initrd kernel params for static IP
  boot.kernelParams = [ "ip=152.53.152.129::152.53.152.1:255.255.252.0::eth0:none" ];
}
