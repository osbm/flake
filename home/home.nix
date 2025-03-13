{config, ...}: {
  imports = [
    ./alacritty.nix
    ./tmux
    ./git.nix
    ./ssh.nix
    ./bash.nix
    ./tlrc.nix
    ./firefox.nix
  ];

  home.username = "osbm";
  home.homeDirectory = "/home/osbm";

  home.packages = [
    # dont install packages here, just use normal nixpkgs
  ];

  home.stateVersion = config.system.stateVersion;
}
