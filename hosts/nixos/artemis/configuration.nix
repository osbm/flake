{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (import "${inputs.mobile-nixos}/lib/configuration.nix" { device = "oneplus-enchilada"; })
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment.gnome.enable = true;
    hardware = {
      systemd-boot.enable = false; # Mobile devices use different bootloader
      sound.enable = false; # Using PulseAudio instead, see below
      hibernation.enable = false;
    };
    programs.graphical.enable = false;

    nixSettings.allowedUnfreePackages = [
      "oneplus-sdm845-firmware-zstd"
      "oneplus-sdm845-firmware"
    ];

    services = {
      # Backup client - pulls vaultwarden backup from apollo
      syncthing.enable = true;
      backup-client = {
        enable = true;
        backups = {
          apollo-vaultwarden = {
            remoteHost = "apollo";
            localPath = "/var/backups/apollo-vaultwarden";
            services = [ "vaultwarden" ];
          };
        };
      };
    };
  };

  services.logind.settings.Login = {
    HandlePowerKey = "lock";
  };

  # GNOME overrides logind's HandlePowerKey, so disable its handler
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "lock-screen";
      };
    }
  ];

  networking.hostName = "artemis";

  nixpkgs.system = "aarch64-linux";

  # Minimal essential packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    lazygit
    asciiquarium
    neovim
    kitty

    # Camera diagnostic + capture stack. Camera does not work yet on
    # mobile-nixos enchilada (kernel 6.4 has no IMX519/IMX376/IMX371
    # sensor drivers — those landed in pmOS's 6.14-based fork). These
    # tools are here so we can probe media topology once the kernel
    # is bumped.
    libcamera
    v4l-utils
    megapixels
  ];

  # Audio: PipeWire is too quiet on this device, use PulseAudio instead
  # Make sure to select "Speakers Output" in settings
  services.pipewire.enable = lib.mkForce false;
  services.pulseaudio.enable = true;

  system.stateVersion = "25.11";
}
