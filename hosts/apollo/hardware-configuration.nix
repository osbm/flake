{ config, lib, ... }:
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/vda"; # Change this to match your actual disk
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };
    zpool = {
      rpool = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          canmount = "off";
          compression = "zstd";
          dnodesize = "auto";
          normalization = "formD";
          xattr = "sa";
          mountpoint = "none";
          encryption = "on";
          keylocation = "prompt";
          keyformat = "passphrase";
        };
        datasets = {
          # Reserved space to prevent pool from becoming full
          "local/reserved" = {
            type = "zfs_fs";
            options = {
              refreservation = "1G";
              mountpoint = "none";
            };
          };
          # Nix store
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "/nix";
          };
          # Persistent data
          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            options = {
              mountpoint = "/persist";
            };
            postCreateHook = "zfs snapshot rpool/safe/persist@empty";
          };
        };
      };
    };
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=2G"
          "mode=755"
        ];
      };
    };
  };

  # ZFS-specific boot configuration
  boot.supportedFilesystems = [ "zfs" ];
  
  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
    
  # Required for ZFS
  networking.hostId = "8425e349"; # Generate your own with: head -c 8 /etc/machine-id
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Mark /persist as needed for boot (required by impermanence)
  fileSystems."/persist".neededForBoot = true;
}