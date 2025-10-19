{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
    inputs.disko.nixosModules.disko
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

      # Disable disko module since we have manual disko config in hardware-configuration.nix
      disko.enable = false;
    };
  };

  i18n.inputMethod.enable = lib.mkForce false;
  system.stateVersion = "25.11";
  networking.hostName = "apollo";
  networking.hostId = "0f7de22e";  # Required for ZFS

  # ZFS configuration
  boot.zfs.requestEncryptionCredentials = true;

  # Initrd SSH for remote unlocking
  boot.initrd.network.enable = true;
  boot.initrd.availableKernelModules = [ "virtio_pci" ];
  boot.initrd.network.ssh = {
    enable = true;
    port = 22;
    shell = "/bin/cryptsetup-askpass";
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k"
    ];
    hostKeys = [ "/etc/ssh/initrd" ];
  };
  boot.initrd.secrets = {
    "/etc/ssh/initrd" = "/etc/ssh/initrd";
  };

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
