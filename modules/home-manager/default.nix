{ lib, ... }:
{
  # Import all home-manager modules
  imports = [
    ./programs
    # no home manager services yet
    # ./services

  ];

  # Basic home-manager configuration
  home.sessionVariables = {
    EDITOR = lib.mkDefault "nvim";
  };

  # Don't set stateVersion here - let it be set by the system configuration
  # home.stateVersion should be set in the system's home-manager configuration

  # Enable basic programs that most users want
  programs.home-manager.enable = true;
}
