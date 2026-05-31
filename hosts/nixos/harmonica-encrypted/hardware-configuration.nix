{
  pkgs,
  lib,
  ...
}:
{
  # Same workaround as harmonica-sd: some rpi-related modules fail to build with
  # strict module closure checks; relax that.
  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # /boot/firmware is the Pi's FAT firmware partition: unencrypted (the VideoCore
  # bootloader cannot read LUKS).  Root lives behind LUKS on the second partition;
  # initrd opens it via the GPT partition label "cryptroot" and exposes
  # /dev/mapper/cryptroot to stage 2.
  fileSystems = {
    "/" = {
      device = "/dev/mapper/cryptroot";
      fsType = "ext4";
    };
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
        "nofail"
      ];
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages;

    initrd = {
      # Modules needed in initrd: USB/SD storage, dm-crypt, FAT codepages for the
      # firmware mount if anything early touches it, and the FS driver.
      availableKernelModules = [
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "mmc_block"
        "dm_mod"
        "dm_crypt"
        "ext4"
        "nls_cp437"
        "nls_iso8859-1"
      ];
      kernelModules = [
        "dm_crypt"
      ];
      luks.devices.cryptroot = {
        # GPT partition label set by the flash recipe (sfdisk name=cryptroot).
        device = "/dev/disk/by-partlabel/cryptroot";
        allowDiscards = true;
      };
    };

    extraModprobeConfig = ''
      options brcmfmac roamoff=1 feature_disable=0x82000
    '';

    # extlinux is enabled only so nixos-install has something to call as a
    # "bootloader install" step; its output goes to /boot/extlinux/ on cryptroot
    # and the Pi firmware never reads it. The flash recipe populates the real
    # /boot/firmware FAT partition (config.txt, cmdline.txt, kernel.img, initrd,
    # dtbs, raspi firmware blobs) manually.
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    # Avoid mdadm warning under sd-image-style installs.
    swraid.enable = lib.mkForce false;
  };

  hardware = {
    enableRedistributableFirmware = lib.mkForce false;
    firmware = [ pkgs.raspberrypiWirelessFirmware ];
    i2c.enable = true;
    deviceTree.filter = "bcm2837-rpi-zero*.dtb";
    deviceTree.overlays = [
      {
        name = "enable-i2c";
        dtsText = ''
          /dts-v1/;
          /plugin/;
          / {
            compatible = "brcm,bcm2837";
            fragment@0 {
              target = <&i2c1>;
              __overlay__ {
                status = "okay";
              };
            };
          };
        '';
      }
    ];
  };

  nixpkgs.hostPlatform = "aarch64-linux";
}
