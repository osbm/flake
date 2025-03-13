{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./alacritty.nix
    ./tmux
    ./git.nix
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
}
