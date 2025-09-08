{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    inputs.osbm-nvim.packages."${pkgs.stdenv.hostPlatform.system}".default
    wget
    git
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
    lm_sensors
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
    dysk
    gnupg
    attic-client
  ];

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  virtualisation.docker.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings = {
      PermitRootLogin = "no";

      # only allow key based logins and not password
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
      PubkeyAuthentication = "yes";
      ChallengeResponseAuthentication = "no";
      UsePAM = false;

      # kick out inactive sessions
      ClientAliveCountMax = 5;
      ClientAliveInterval = 60;
    };
  };
}
