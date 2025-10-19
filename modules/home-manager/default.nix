{ lib, ... }:
{
  # Import all home-manager modules
  imports = [
    ./programs
    ./services
  ];

  # Basic home-manager configuration
  home.sessionVariables = {
    EDITOR = lib.mkDefault "nvim";
  };

  # Enable basic programs that most users want
  programs.home-manager.enable = true;
}
