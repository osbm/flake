{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./alacritty.nix
    ./tmux
    ./ghostty.nix
    ./git.nix
    ./gtk.nix
    ./ssh.nix
    ./bash.nix
    ./direnv.nix
    ./firefox.nix
    ./fish.nix
    ./tlrc.nix
    ./starship.nix
    ./zoxide.nix
  ];

  home.username = "osbm";
  home.homeDirectory = "/home/osbm";

  home.packages = [
    pkgs.lazygit
  ];

  home.stateVersion = config.system.stateVersion;

  enableGTK = config.myModules.enableKDE;
  enableFirefox = config.myModules.enableKDE;
  enableAlacritty = config.myModules.enableKDE;
  enableGhostty = config.myModules.enableKDE;
}
