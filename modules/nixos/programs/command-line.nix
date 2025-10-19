{ pkgs, inputs, lib, config, ... }:
{
  config = lib.mkIf config.osbmModules.programs.commandLine.enable {
    environment.systemPackages = with pkgs; [
      wget
      nano
      git
      lazygit
      lazysql
      git-lfs
      gnumake
      zip
      fish
      trash-cli
      tmux
      zoxide
      htop
      unzip
      tlrc
      btop
      pciutils
      cloc
      neofetch
      pfetch
      inxi
      jq
      dig
      onefetch
      just
      nixd
      eza
      gh
      starship
      tree
      nix-output-monitor
      yazi
      ripgrep
      nh
      comma
      nix-inspect
      bat
      fd
      du-dust
      duf
      (pkgs.writeShellScriptBin "wake-ymir" ''
        echo waking up ymir
        ${pkgs.wakeonlan}/bin/wakeonlan 04:7c:16:e6:d9:13
      '')
    ];
  };
}
