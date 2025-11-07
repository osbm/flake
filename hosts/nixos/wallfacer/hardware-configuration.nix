{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "ehci_pci"
      "megaraid_sas"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/8270dba5-6d89-438a-90bd-d9f29b20cb5b";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/A1EB-43F8";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/data/atreus" = {
      device = "/dev/disk/by-uuid/1840c2af-fdb2-48b6-8555-2cecd1afb106";
      fsType = "ext4";
    };
    # 500 gb nvme pcie
    "/data/kasio" = {
      device = "/dev/disk/by-uuid/af74aa48-8513-4e31-a4b7-9fdd138e0002";
      fsType = "ext4";
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/534ea30c-2664-498b-915f-41b037eba01b"; }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1np0.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno2np1.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno3.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno4.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
