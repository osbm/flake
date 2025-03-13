{
  lib,
  pkgs,
  ...
}: {
  user.userName = lib.mkForce "osbm"; # fuck i hate unmaintained projects
  environment.packages = with pkgs; [
    vim # or some other editor, e.g. nano or neovim

    # Some common stuff that people expect to have
    procps
    #killall
    #diffutils
    inetutils
    findutils
    utillinux
    tzdata
    hostname
    man
    gnugrep
    #gnupg
    #gnused
    #gnutar
    #bzip2
    #gzip
    #xz
    zip
    unzip
    fish
    tmux
    nano
    ripgrep
    git
    openssh
    just
    nh
    (pkgs.writeShellScriptBin "sshd-start" ''
      echo "Starting sshd on port 8022"
      ${pkgs.openssh}/bin/sshd
    '')
    (pkgs.writeShellScriptBin "wake-ymir" ''
      echo waking up ymir
      ${pkgs.wakeonlan}/bin/wakeonlan 04:7c:16:e6:d9:13
    '')
    # obsidian tools
    # i need a background process that can just keep pulling and pushing changes just like the obsidian git plugin
    # (pkgs.writeShellScriptBin "rerouting-sync-start" ''
    #   cd /storage/emulated/0/Documents/rerouting
    #   git pull
    #   git add --all
    #   git commit -m "Android sync"
    #   git push
    # '')
    (pkgs.writeShellScriptBin "rerouting-status" ''
      cd /storage/emulated/0/Documents/rerouting
      git fetch
      git status
    '')
    (pkgs.writeShellScriptBin "rerouting-pull" ''
      cd /storage/emulated/0/Documents/rerouting
      git pull
    '')
    (pkgs.writeShellScriptBin "rerouting-push" ''
      cd /storage/emulated/0/Documents/rerouting
      git add --all
      git commit -m "Android sync"
      git push
    '')
    ani-cli
  ];

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  environment.etcBackupExtension = ".bak";

  # Read the changelog before changing this value
  system.stateVersion = "24.05";
  #services.openssh.enable=true;
  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Set your time zone
  #time.timeZone = "Europe/Berlin";

  build.activation.sshd = ''
    if [ ! -e /etc/ssh/ssh_host_ed25519_key ]; then
      $VERBOSE_ECHO "Generating host keys..."
      $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -a 32 -f "/etc/ssh/ssh_host_ed25519_key" -N ""
    fi
  '';

  environment.etc."ssh/sshd_config".text = ''
    AcceptEnv LANG LC_*
    KbdInteractiveAuthentication no
    PasswordAuthentication no
    PermitRootLogin no
    Port 8022
    PrintMotd no
    AuthorizedKeysFile /etc/ssh/authorized_keys.d/%u
  '';
  environment.etc."ssh/authorized_keys.d/osbm".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k
  '';
}
