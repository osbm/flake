{
  config,
  lib,
  pkgs,
  system,
  ...
}:
{
  imports = [
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;
  # Set environment variable for allowing non-free packages
  environment.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  environment.systemPackages = with pkgs; [
    # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    curl
    parted
    nano
    comma
    just
    age
    neovim
    wget
  ];

  services.openssh.enable = true;
}
