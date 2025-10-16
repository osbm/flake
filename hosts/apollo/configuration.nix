{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
  ];

  myModules = {
    enableKDE = false;
    enableFonts = false;
    blockYoutube = false;
    blockTwitter = false;
  };

  i18n.inputMethod.enable = lib.mkForce false; # no need for japanese input method
  system.stateVersion = "25.11";
  networking.hostName = "apollo";

  # Enable zram swap
  zramSwap.enable = true;

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
    # kernelParams = [ "ip=<ipv4_address>::<ipv4_gateway>:<ipv4_netmask>::<interface>:none" ];
    
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

  # Static networking (if needed for VPS)
  # networking = {
  #   useDHCP = false;
  #   interfaces.ens3 = {
  #     useDHCP = false;
  #     ipv4.addresses = [{
  #       address = "<ipv4_address>";
  #       prefixLength = <prefix_length>;
  #     }];
  #     ipv6.addresses = [{
  #       address = "<ipv6_address>";
  #       prefixLength = <prefix_length>;
  #     }];
  #   };
  #   defaultGateway = "<ipv4_gateway>";
  #   defaultGateway6 = { address = "<ipv6_gateway>"; interface = "ens3"; };
  # };
}
