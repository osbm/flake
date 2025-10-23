{ lib, config, ... }:
{
  options.osbmModules = {
    # Desktop Environment
    desktopEnvironment = lib.mkOption {
      type = lib.types.enum [
        "plasma"
        "gnome"
        "none"
      ];
      default = "none";
      description = "Which desktop environment to use";
    };

    # Machine Type
    machineType = lib.mkOption {
      type = lib.types.enum [
        "desktop"
        "laptop"
        "server"
        "embedded"
        "mobile"
      ];
      default = "server";
      description = "Type of machine for appropriate defaults";
    };

    # Users
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "osbm"
      ]
      ++ lib.optionals (
        config.osbmModules.machineType == "desktop" || config.osbmModules.machineType == "laptop"
      ) [ "bayram" ];
      description = "List of users to create. `osbm` is my main user, and `bayram` is for my family (only on desktop/laptop).";
    };

    defaultUser = lib.mkOption {
      type = lib.types.str;
      default = "osbm";
      description = "Default user for the system";
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
          default = config.osbmModules.desktopEnvironment != "none";
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

      adbFastboot = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable ADB and Fastboot for Android development";
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

      syncthing.enable = lib.mkEnableOption "syncthing";
      jellyfin.enable = lib.mkEnableOption "jellyfin";
      nextcloud.enable = lib.mkEnableOption "nextcloud";
      vaultwarden.enable = lib.mkEnableOption "vaultwarden";
      ollama.enable = lib.mkEnableOption "ollama";
      forgejo.enable = lib.mkEnableOption "forgejo";
      caddy.enable = lib.mkEnableOption "caddy";
      atticd.enable = lib.mkEnableOption "atticd";
      cloudflared.enable = lib.mkEnableOption "cloudflared";
      cloudflare-dyndns.enable = lib.mkEnableOption "cloudflare-dyndns";
      glance.enable = lib.mkEnableOption "glance";
      hydra.enable = lib.mkEnableOption "hydra";
      vscode-server.enable = lib.mkEnableOption "vscode-server";
      wanikani-bypass-lessons.enable = lib.mkEnableOption "wanikani-bypass-lessons";
      wanikani-fetch-data.enable = lib.mkEnableOption "wanikani-fetch-data";
      wanikani-stats.enable = lib.mkEnableOption "wanikani-stats";
    };

    # Hardware
    hardware = {
      bluetooth = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.osbmModules.desktopEnvironment != "none";
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

      nvidiaDriver = {
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

    # Virtualization
    virtualization = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable virtualization support (libvirt, docker, etc.)";
      };

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
        default = config.osbmModules.desktopEnvironment != "none";
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
