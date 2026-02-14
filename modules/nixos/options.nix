{ lib, config, ... }:
{
  options.osbmModules = {
    # Desktop Environment
    desktopEnvironment = {
      plasma.enable = lib.mkEnableOption "plasma";
      gnome.enable = lib.mkEnableOption "gnome";
      niri.enable = lib.mkEnableOption "niri";
      hyprland.enable = lib.mkEnableOption "hyprland";
      # none is true if all above are false, just for easier checks
      none = lib.mkOption {
        type = lib.types.bool;
        default =
          !(
            config.osbmModules.desktopEnvironment.plasma.enable
            || config.osbmModules.desktopEnvironment.gnome.enable
            || config.osbmModules.desktopEnvironment.niri.enable
            || config.osbmModules.desktopEnvironment.hyprland.enable
          );
        description = "True if no desktop environment is enabled";
      };
    };

    defaultUser = lib.mkOption {
      type = lib.types.str;
      default = "osbm";
      description = "Default user for the system";
    };

    familyUser.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable family user account";
    };

    # Home Manager
    homeManager = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable home-manager integration";
      };
    };

    # Agenix
    agenix = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable agenix for secrets management";
      };
    };

    # Nix Settings
    nixSettings = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable custom nix settings";
      };
    };

    # Programs
    programs = {
      steam = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Steam gaming platform";
        };
      };

      graphical = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = !config.osbmModules.desktopEnvironment.none;
          description = "Enable graphical applications";
        };
      };

      commandLine = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable common command line tools";
        };
      };

      neovim = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable neovim with custom configuration";
        };
      };

      arduino = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Arduino IDE and development tools";
        };
      };
    };

    # Services
    services = {
      openssh = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable OpenSSH server";
        };
      };

      tailscale = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Tailscale VPN";
        };
      };

      actual.enable = lib.mkEnableOption "actual";
      anubis.enable = lib.mkEnableOption "anubis";
      syncthing.enable = lib.mkEnableOption "syncthing";
      jellyfin.enable = lib.mkEnableOption "jellyfin";
      mailserver.enable = lib.mkEnableOption "mailserver";
      vaultwarden.enable = lib.mkEnableOption "vaultwarden";
      nginx.enable = lib.mkEnableOption "nginx";
      ntfy.enable = lib.mkEnableOption "ntfy";
      radicale.enable = lib.mkEnableOption "radicale";
      grafana.enable = lib.mkEnableOption "grafana dashboard";
      ollama.enable = lib.mkEnableOption "ollama";
      forgejo.enable = lib.mkEnableOption "forgejo";
      atticd.enable = lib.mkEnableOption "atticd";
      glance.enable = lib.mkEnableOption "glance";
      hydra.enable = lib.mkEnableOption "hydra";
      immich.enable = lib.mkEnableOption "immich";
      vscode-server.enable = lib.mkEnableOption "vscode-server";
      wanikani-bypass-lessons.enable = lib.mkEnableOption "wanikani-bypass-lessons";
      wanikani-fetch-data.enable = lib.mkEnableOption "wanikani-fetch-data";

      wanikani-stats = {
        enable = lib.mkEnableOption "wanikani-stats";

        logDirectory = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/wanikani-logs";
          description = "Directory to get the log archives";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8501;
          description = "Port for the WaniKani Stats service";
        };
      };

      wakeup-ymir.enable = lib.mkEnableOption "wakeup-ymir";

      wakeup-music-player = {
        enable = lib.mkEnableOption "wakeup-music-player";

        musicFile = lib.mkOption {
          type = lib.types.path;
          default = "/home/osbm/Music/wakeup.mp3";
          description = "Path to the music file to play on wakeup";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "osbm";
          description = "User to run the music player as";
        };
      };

      system-logger = {
        enable = lib.mkEnableOption "system-logger";

        logDirectory = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/system-logger";
          description = "Directory to store log archives";
        };

        maxSizeMB = lib.mkOption {
          type = lib.types.int;
          default = 1;
          description = "Maximum size of daily log archive in megabytes";
        };

        retentionDays = lib.mkOption {
          type = lib.types.int;
          default = 30;
          description = "Number of days to retain log archives";
        };
      };

      # Backup server - exposes data for pull-based backups
      backup-server = {
        enable = lib.mkEnableOption "backup server (exposes data for pull-based backups)";

        zfsSnapshots = {
          enable = lib.mkEnableOption "automatic ZFS snapshots of /persist";

          frequent = lib.mkOption {
            type = lib.types.int;
            default = 4;
            description = "Number of frequent (15-min) snapshots to keep";
          };

          hourly = lib.mkOption {
            type = lib.types.int;
            default = 24;
            description = "Number of hourly snapshots to keep";
          };

          daily = lib.mkOption {
            type = lib.types.int;
            default = 7;
            description = "Number of daily snapshots to keep";
          };

          weekly = lib.mkOption {
            type = lib.types.int;
            default = 4;
            description = "Number of weekly snapshots to keep";
          };

          monthly = lib.mkOption {
            type = lib.types.int;
            default = 12;
            description = "Number of monthly snapshots to keep";
          };
        };
      };

      # Backup client - pulls backups from remote servers
      backup-client = {
        enable = lib.mkEnableOption "backup client (pulls data from remote servers)";

        backups = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                remoteHost = lib.mkOption {
                  type = lib.types.str;
                  description = "Remote host to backup from (e.g., apollo.tail-scale.ts.net)";
                };

                remoteUser = lib.mkOption {
                  type = lib.types.str;
                  default = "root";
                  description = "Remote user for SSH connection";
                };

                localPath = lib.mkOption {
                  type = lib.types.str;
                  description = "Local path where backups will be stored";
                };

                fullBackup = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Whether to backup the entire /persist directory";
                };

                services = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "List of services to backup (e.g., ['vaultwarden', 'immich'])";
                  example = [
                    "vaultwarden"
                    "immich"
                    "forgejo"
                  ];
                };

                schedule = lib.mkOption {
                  type = lib.types.str;
                  default = "daily";
                  description = "Backup schedule (systemd timer format)";
                  example = "daily";
                };
              };
            }
          );
          default = { };
          description = "Backup configurations";
        };
      };
    };

    # Hardware
    hardware = {
      bluetooth = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = !config.osbmModules.desktopEnvironment.none;
          description = "Enable Bluetooth support";
        };
      };

      sound = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable sound with pipewire";
        };
      };

      nvidia = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable NVIDIA proprietary drivers";
        };
      };

      hibernation = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable hibernation support";
        };
      };

      wakeOnLan = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable wake-on-LAN support";
        };
      };

      systemd-boot.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use systemd-boot bootloader";
      };

      # Disko configuration (inspired by ZFS.nix)
      disko = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable custom disk configuration with disko";
        };

        amReinstalling = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Am I reinstalling and want to save the storage pool";
        };

        fileSystem = lib.mkOption {
          type = lib.types.enum [
            "zfs"
            "ext4"
          ];
          default = "ext4";
          description = "Root filesystem type";
        };

        initrd-ssh = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable SSH in initrd for remote unlocking";
          };

          authorizedKeys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "SSH public keys for initrd access";
          };

          ethernetDrivers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Ethernet drivers to load in initrd";
          };
        };

        zfs = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable ZFS filesystem";
          };

          hostID = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "ZFS host ID (8 hex characters)";
          };

          root = {
            useTmpfs = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Use tmpfs for root instead of ZFS (with ZFS datasets for /nix and /persist)";
            };

            tmpfsSize = lib.mkOption {
              type = lib.types.str;
              default = "2G";
              description = "Size of tmpfs root filesystem";
            };

            encrypt = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Encrypt root ZFS pool";
            };

            disk1 = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "First disk device name (e.g., nvme0n1)";
            };

            disk2 = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Second disk device name for mirroring";
            };

            reservation = lib.mkOption {
              type = lib.types.str;
              default = "20G";
              description = "ZFS reservation size";
            };

            mirror = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Mirror the root ZFS pool";
            };

            impermanenceRoot = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Wipe the root directory on boot (impermanence)";
            };
          };

          storage = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable separate storage ZFS pool";
            };

            disks = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Storage pool disk device names";
            };

            reservation = lib.mkOption {
              type = lib.types.str;
              default = "20G";
              description = "Storage pool ZFS reservation";
            };

            mirror = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Mirror the storage ZFS pool";
            };
          };
        };
      };
    };

    virtualisation = {
      docker = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Docker";
        };
      };

      podman = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Podman";
        };
      };

      libvirt = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable libvirt/KVM";
        };
      };
    };

    # Emulation
    emulation = {
      aarch64 = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable aarch64 emulation via binfmt";
        };
      };
    };

    # Internationalization
    i18n = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable internationalization settings";
      };
    };

    # Fonts
    fonts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = !config.osbmModules.desktopEnvironment.none;
        description = "Enable custom fonts";
      };
    };

    # Nix Index
    nixIndex = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable nix-index for command-not-found";
      };
    };
  };
}
