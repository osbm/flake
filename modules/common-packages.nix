{
  pkgs,
  inputs,
  ...
}:
  {
    environment.systemPackages = with pkgs; [
    (if !pkgs.stdenv.hostPlatform.isDarwin
    then
      inputs.osbm-nvim.packages."${pkgs.stdenv.hostPlatform.system}".default
    else null
    )
    wget
    git
    lazygit
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
    (pkgs.writeShellScriptBin "wake-ymir" ''
      echo waking up ymir
      ${pkgs.wakeonlan}/bin/wakeonlan 04:7c:16:e6:d9:13
    '')
    btop
    pciutils
    # lm_sensors
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
    dust
    # dysk
    gnupg
    attic-client
  ];

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
