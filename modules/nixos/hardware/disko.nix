{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.osbmModules.hardware.disko;
  inherit (config.networking) hostName;

  # Default authorized keys for initrd SSH
  defaultAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF1TFwXbqdC1UyG75q3HO1n7/L3yxpeRLIq2kQ9DalI"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYSJ9ywFRJ747tkhvYWFkx/Y9SkLqv3rb7T1UuXVBWo"
  ];

  authorizedKeys =
    if cfg.initrd-ssh.authorizedKeys != [ ] then
      cfg.initrd-ssh.authorizedKeys
    else
      defaultAuthorizedKeys;
in
{
  imports = [
    inputs.disko.nixosModules.default
  ];

  config = lib.mkMerge [
    # Systemd-boot setup
    (lib.mkIf (cfg.enable && cfg.systemd-boot) {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    })

    # Initrd SSH for remote unlocking
    (lib.mkIf (cfg.enable && cfg.initrd-ssh.enable) {
      boot.initrd.network.enable = true;
      boot.initrd.availableKernelModules = cfg.initrd-ssh.ethernetDrivers;
      boot.kernelParams = [ "ip=::::${hostName}-initrd::dhcp" ];
      boot.initrd.network.ssh = {
        enable = true;
        port = 22;
        shell = "/bin/cryptsetup-askpass";
        authorizedKeys = authorizedKeys;
        hostKeys = [ "/etc/ssh/initrd" ];
      };
      boot.initrd.secrets = {
        "/etc/ssh/initrd" = "/etc/ssh/initrd";
      };
    })

    # ZFS Configuration
    (lib.mkIf (cfg.enable && cfg.zfs.enable) {
      networking.hostId = cfg.zfs.hostID;

      environment.systemPackages = [ pkgs.zfs-prune-snapshots ];

      boot = {
        # ZFS does not support swapfiles
        kernelParams = [
          "nohibernate"
          "zfs.zfs_arc_max=17179869184" # 16GB ARC max
        ];
        supportedFilesystems = [
          "vfat"
          "zfs"
        ];
        zfs = {
          devNodes = "/dev/disk/by-id/";
          forceImportAll = true;
          requestEncryptionCredentials = cfg.zfs.root.encrypt;
        };
      };

      services.zfs = {
        autoScrub.enable = true;
        trim.enable = true;
      };

      # Disko configuration for ZFS
      disko.devices = {
        disk = lib.mkMerge [
          # Storage pool disks (if enabled and not reinstalling)
          (lib.mkIf (cfg.zfs.storage.enable && !cfg.amReinstalling) (
            lib.mkMerge (
              map (diskname: {
                "${diskname}" = {
                  type = "disk";
                  device = "/dev/${diskname}";
                  content = {
                    type = "gpt";
                    partitions = {
                      luks = {
                        size = "100%";
                        content = {
                          type = "luks";
                          name = "stg${diskname}";
                          settings.allowDiscards = true;
                          passwordFile = "/tmp/secret.key";
                          content = {
                            type = "zfs";
                            pool = "zstorage";
                          };
                        };
                      };
                    };
                  };
                };
              }) cfg.zfs.storage.disks
            )
          ))

          # Root disk 1 (primary)
          {
            one = lib.mkIf (cfg.zfs.root.disk1 != "") {
              type = "disk";
              device = "/dev/${cfg.zfs.root.disk1}";
              content = {
                type = "gpt";
                partitions = {
                  ESP = {
                    label = "EFI";
                    name = "ESP";
                    size = "2048M";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                      mountOptions = [
                        "defaults"
                        "umask=0077"
                      ];
                    };
                  };

                  # Encrypted root partition
                  luks = lib.mkIf cfg.zfs.root.encrypt {
                    size = "100%";
                    content = {
                      type = "luks";
                      name = "crypted1";
                      settings.allowDiscards = true;
                      passwordFile = "/tmp/secret.key";
                      content = {
                        type = "zfs";
                        pool = "zroot";
                      };
                    };
                  };

                  # Unencrypted root partition
                  notluks = lib.mkIf (!cfg.zfs.root.encrypt) {
                    size = "100%";
                    content = {
                      type = "zfs";
                      pool = "zroot";
                    };
                  };
                };
              };
            };

            # Root disk 2 (mirror)
            two = lib.mkIf (cfg.zfs.root.disk2 != "") {
              type = "disk";
              device = "/dev/${cfg.zfs.root.disk2}";
              content = {
                type = "gpt";
                partitions = {
                  luks = {
                    size = "100%";
                    content = {
                      type = "luks";
                      name = "crypted2";
                      settings.allowDiscards = true;
                      passwordFile = "/tmp/secret.key";
                      content = {
                        type = "zfs";
                        pool = "zroot";
                      };
                    };
                  };
                };
              };
            };
          }
        ];

        # ZFS pools
        zpool = {
          # Root pool
          zroot = {
            type = "zpool";
            mode = lib.mkIf cfg.zfs.root.mirror "mirror";
            rootFsOptions = {
              canmount = "off";
              checksum = "edonr";
              compression = "zstd";
              dnodesize = "auto";
              mountpoint = "none";
              normalization = "formD";
              relatime = "on";
              "com.sun:auto-snapshot" = "false";
            };
            options = {
              ashift = "12";
              autotrim = "on";
            };
            datasets = {
              # Reserved space for ZFS CoW operations
              reserved = {
                type = "zfs_fs";
                options = {
                  canmount = "off";
                  mountpoint = "none";
                  reservation = cfg.zfs.root.reservation;
                };
              };

              # SSH keys dataset
              etcssh = {
                type = "zfs_fs";
                options.mountpoint = "legacy";
                mountpoint = "/etc/ssh";
                options."com.sun:auto-snapshot" = "false";
                postCreateHook = "zfs snapshot zroot/etcssh@empty";
              };

              # Persistent data
              persist = {
                type = "zfs_fs";
                options.mountpoint = "legacy";
                mountpoint = "/persist";
                options."com.sun:auto-snapshot" = "false";
                postCreateHook = "zfs snapshot zroot/persist@empty";
              };

              # Persistent save data
              persistSave = {
                type = "zfs_fs";
                options.mountpoint = "legacy";
                mountpoint = "/persist/save";
                options."com.sun:auto-snapshot" = "false";
                postCreateHook = "zfs snapshot zroot/persistSave@empty";
              };

              # Nix store
              nix = {
                type = "zfs_fs";
                options.mountpoint = "legacy";
                mountpoint = "/nix";
                options = {
                  atime = "off";
                  canmount = "on";
                  "com.sun:auto-snapshot" = "false";
                };
                postCreateHook = "zfs snapshot zroot/nix@empty";
              };

              # Root filesystem
              root = {
                type = "zfs_fs";
                options.mountpoint = "legacy";
                options."com.sun:auto-snapshot" = "false";
                mountpoint = "/";
                postCreateHook = "zfs snapshot zroot/root@empty";
              };
            };
          };

          # Storage pool (if enabled and not reinstalling)
          zstorage = lib.mkIf (cfg.zfs.storage.enable && !cfg.amReinstalling) {
            type = "zpool";
            mode = lib.mkIf cfg.zfs.storage.mirror "mirror";
            rootFsOptions = {
              canmount = "off";
              checksum = "edonr";
              compression = "zstd";
              dnodesize = "auto";
              mountpoint = "none";
              normalization = "formD";
              relatime = "on";
              "com.sun:auto-snapshot" = "false";
            };
            options = {
              ashift = "12";
              autotrim = "on";
            };
            datasets = {
              # Reserved space
              reserved = {
                type = "zfs_fs";
                options = {
                  canmount = "off";
                  mountpoint = "none";
                  reservation = cfg.zfs.storage.reservation;
                };
              };

              # Main storage
              storage = {
                type = "zfs_fs";
                mountpoint = "/storage";
                options = {
                  atime = "off";
                  canmount = "on";
                  "com.sun:auto-snapshot" = "false";
                };
              };

              # Persistent save in storage
              persistSave = {
                type = "zfs_fs";
                mountpoint = "/storage/save";
                options = {
                  atime = "off";
                  canmount = "on";
                  "com.sun:auto-snapshot" = "false";
                };
              };
            };
          };
        };
      };

      # Needed for agenix - SSH keys must be available before ZFS mounts
      fileSystems."/etc/ssh".neededForBoot = true;

      # Needed for impermanence
      fileSystems."/persist".neededForBoot = true;
      fileSystems."/persist/save".neededForBoot = true;
    })

    # Impermanence: wipe root on boot
    (lib.mkIf (cfg.enable && cfg.zfs.enable && cfg.zfs.root.impermanenceRoot) {
      boot.initrd.postResumeCommands = lib.mkAfter ''
        zfs rollback -r zroot/root@empty
      '';
    })
  ];
}
