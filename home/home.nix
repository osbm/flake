{
  username,
  homeDirectory,
  stateVersion,
  config,
  enableGTK ? config.myModules.enableKDE,
  enableGhostty ? config.myModules.enableKDE,
  pkgs,
  ...
}:
{
  imports = [
    ./alacritty.nix
    ./tmux
    ./ghostty.nix
    ./git.nix
    ./gpg.nix
    ./gtk.nix
    ./ssh.nix
    ./bash.nix
    ./direnv.nix
    ./firefox.nix
    ./fish.nix
    ./tlrc.nix
    ./starship.nix
    ./wezterm.nix
    ./zoxide.nix
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;

  home.packages = [
    pkgs.lazygit
  ];

  home.stateVersion = stateVersion;

  enableGTK = enableGTK;
  enableFirefox = config.myModules.enableKDE;
  enableAlacritty = config.myModules.enableKDE;
  enableGhostty = enableGhostty;
  enableWezterm = config.myModules.enableKDE;
}
