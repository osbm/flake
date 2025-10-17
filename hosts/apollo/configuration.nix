{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common-packages.nix
    # ../../modules/services/tailscale.nix
    # ../../modules/services/openssh.nix
    ../../modules/nix-settings.nix
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
  ];

  # myModules = {
  #   enableKDE = false;
  #   enableFonts = false;
  #   blockYoutube = false;
  #   blockTwitter = false;
  # };

  i18n.inputMethod.enable = lib.mkForce false; # no need for japanese input method
  system.stateVersion = "25.11";
  networking.hostName = "apollo";

  networking.hostId = "0f7de22e"; # Generate your own with: head -c 8 /etc/machine-id

  # Enable zram swap
  zramSwap.enable = true;

  users.users.root.initialPassword = "changeme";
  users.mutableUsers = false;

  # Persistence configuration
  environment.persistence."/persist" = {
    hideMounts = true;
    files = [
      "/etc/machine-id"
    ];
    directories = [
      "/var/log"
      "/var/lib/tailscale"
      "/var/lib/borg"
      "/var/lib/nixos"
    ];
  };

  # Remote ZFS unlocking in initrd
  boot = {
    # Static IP in initrd - adjust these values for your network
    kernelParams = [ "ip=152.53.152.129::152.53.152.1:255.255.252.0::ens3:none" ];

    initrd = {
      # Network driver for initrd - change to match your hardware
      # Common options: "virtio_pci" (VMs), "e1000e", "igb", "r8169"
      availableKernelModules = [ "virtio_pci" ];
      
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          # Generate with: ssh-keygen -t ed25519 -N "" -f /persist/etc/ssh/ssh_host_ed25519_key_initrd
          hostKeys = [ "/persist/etc/ssh/ssh_host_ed25519_key_initrd" ];
          # Add your SSH public key here
          authorizedKeys = [ 
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k"
          ];
        };
        # Auto-prompt for ZFS password on SSH login
        postCommands = ''
          cat <<EOF > /root/.profile
          if pgrep -x "zfs" > /dev/null
          then
            zfs load-key -a
            killall zfs
          else
            echo "zfs not running -- maybe the pool is taking some time to load for some unforseen reason."
          fi
          EOF
        '';
      };
    };
  };

  # SSH host keys on persistent storage
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    hostKeys = [
      {
        bits = 4096;
        path = "/persist/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
      }
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

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
}
