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
  # Kernel and filesystem configuration for mobile-nixos
  mobile.boot.stage-1.kernel = {
    modules = [ "ext4" ]; # Modules to load in stage-1
    modular = true; # Enable kernel modules
  };

  boot.supportedFilesystems = [
    "ext4"
    "vfat"
  ];

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
