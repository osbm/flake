{ lib, pkgs, ... }:
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

  home.packages = [ pkgs.forgejo-cli ];

  home.shellAliases = {
    c = "code .";
    l = "eza --all --long --git --icons --group --sort size --header --group-directories-first";
    ll = "eza --all --long --git --icons --group --sort name --header --group-directories-first";
    free = "free -h";
    df = "df -h";
    du = "du -h";
    lg = "lazygit";
    onefetch = "onefetch -T prose -T programming -T data";
    fj = "${lib.getExe pkgs.forgejo-cli} --host git.osbm.dev";
  };

  # Don't set stateVersion here - let it be set by the system configuration
  # home.stateVersion should be set in the system's home-manager configuration

  # Enable basic programs that most users want
  programs.home-manager.enable = true;
}
