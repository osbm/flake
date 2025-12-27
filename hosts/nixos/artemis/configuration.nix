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
    hardware.systemd-boot.enable = false; # Mobile devices use different bootloader
    programs.graphical.enable = false;

    services = {
      # Backup client - pulls vaultwarden backup from apollo
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

  # mobile-nixos needs aliases (uses nettools instead of net-tools)
  nixpkgs = {
    config = {
      allowAliases = true;
      allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "oneplus-sdm845-firmware-zstd"
          "oneplus-sdm845-firmware"
        ];
    };
    system = "aarch64-linux";
  };

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
  ];

  system.stateVersion = "25.11";
}
