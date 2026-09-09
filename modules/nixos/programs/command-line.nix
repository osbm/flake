{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  config = lib.mkIf config.osbmModules.programs.commandLine.enable {
    osbmModules.nixSettings.allowedUnfreePackages = lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
      "claude-code"
    ];

    environment.systemPackages =
      # claude-code from llm-agents.nix (numtide) — tracks upstream faster than
      # nixpkgs. On darwin the native self-updating installer is used instead.
      lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
      ]
      ++ (with pkgs; [
        # networking
        wget
        curl
        dig
        rclone

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
        nh

        # information and vanity
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
        file
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
      ]);
  };
}
