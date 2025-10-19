{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
    inputs.impermanence.nixosModules.impermanence
  ];

  osbmModules = {
    desktopEnvironment = "none";
    machineType = "server";
    users = [ "osbm" ];
    defaultUser = "osbm";

    nixSettings.enable = true;

    programs = {
      commandLine.enable = true;
      neovim.enable = true;
    };

    services = {
      openssh.enable = true;
    };

    hardware = {
      sound.enable = false;
      hibernation.enable = false;

      disko = {
        enable = true;
        fileSystem = "zfs";
        systemd-boot = true;
        
        initrd-ssh = {
          enable = true;
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k"
          ];
          ethernetDrivers = [ "virtio_pci" ];
        };
        
        zfs = {
          enable = true;
          hostID = "0f7de22e";
          root = {
            useTmpfs = false;  # Use ZFS root, not tmpfs
            encrypt = true;
            disk1 = "vda";
            impermanenceRoot = true;  # Wipe root on boot with ZFS snapshots
          };
        };
      };
    };
  };

  i18n.inputMethod.enable = lib.mkForce false;
  system.stateVersion = "25.11";
  networking.hostName = "apollo";

  # Enable zram swap
  zramSwap.enable = true;

  users.users.osbm.initialPassword = "changeme";
  users.mutableUsers = false;

  # Network configuration
  networking = {
    useDHCP = false;
    interfaces.ens3 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "152.53.152.129";
        prefixLength = 22;
      }];
      ipv6.addresses = [{
        address = "2a00:11c0:47:3b2a::1";
        prefixLength = 64;
      }];
    };
    defaultGateway = "152.53.152.1";
    defaultGateway6 = { address = "fe80::1"; interface = "ens3"; };
  };

  # Override initrd kernel params for static IP
  boot.kernelParams = [ "ip=152.53.152.129::152.53.152.1:255.255.252.0::ens3:none" ];
}
