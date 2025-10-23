{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    (import "${inputs.mobile-nixos}/lib/configuration.nix" { device = "oneplus-enchilada"; })
    ../../../modules/nixos
  ];

  osbmModules = {
    desktopEnvironment = "gnome";
    machineType = "mobile";
    hardware.systemd-boot.enable = false; # Mobile devices use different bootloader
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
  # set platform to aarch64-linux
  nixpkgs.system = "aarch64-linux";
}
