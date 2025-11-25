{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.osbmModules.programs.commandLine.enable {
    environment.systemPackages = with pkgs; [
      # networking
      wget
      curl
      dig

      # text editors
      nano

      # version control
      (pkgs.gitFull.override {
        osxkeychainSupport = false;
      })
      git-lfs
      lazygit
      gh

      # nix tools
      nix-output-monitor
      nixd
      nix-inspect
      comma
      nh

      # information and vanity
      neofetch
      onefetch
      pfetch
      htop
      btop
      cloc
      inxi
      tlrc
      pciutils

      # basic quality of life
      eza
      dysk
      trash-cli
      zoxide
      lazysql
      jq
      ripgrep
      dust
      bat
      just
      tree
      fd
      yazi
      duf

      # archives
      zip
      unzip

      # shell
      fish
      starship

      # multiplexers
      tmux

      (pkgs.writeShellScriptBin "wake-ymir" ''
        echo waking up ymir
        ${pkgs.wakeonlan}/bin/wakeonlan 04:7c:16:e6:d9:13
      '')
    ];
  };
}
