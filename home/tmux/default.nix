{
  pkgs,
  lib,
  ...
}:
let
  wanikani-current-reviews-script = builtins.path { path = ./wanikani-current-reviews.sh; };
  wanikani-level-script = builtins.path { path = ./wanikani-level.sh; };
  wanikani-progression-script = builtins.path { path = ./wanikani-progression.sh; };
  tmux-dracula = pkgs.tmuxPlugins.mkTmuxPlugin rec {
    pluginName = "dracula";
    version = "3.0.0";
    src = pkgs.fetchFromGitHub {
      owner = "dracula";
      repo = "tmux";
      rev = "v${version}";
      hash = "sha256-VY4PyaQRwTc6LWhPJg4inrQf5K8+bp0+eqRhR7+Iexk=";
    };
    postInstall = ''
      # i am adding my custom widget to the plugin here cp the wanikani.sh script to the plugin directory
      cp ${wanikani-current-reviews-script} $target/scripts/wanikani-current-reviews.sh
      cp ${wanikani-level-script} $target/scripts/wanikani-level.sh
      cp ${wanikani-progression-script} $target/scripts/wanikani-progression.sh
    '';
    meta = with pkgs.lib; {
      homepage = "https://draculatheme.com/tmux";
      description = "Feature packed Dracula theme for tmux!";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = with maintainers; [ ethancedwards8 ];
    };
  };
in
{
  programs.tmux = {
    enable = true;
    historyLimit = 100000;
    baseIndex = 1;
    shortcut = "s";
    mouse = true;
    shell = lib.getExe pkgs.fish;
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.better-mouse-mode
      {
        plugin = tmux-dracula;
        extraConfig = ''
          set -g @dracula-plugins "custom:wanikani-level.sh custom:wanikani-progression.sh custom:wanikani-current-reviews.sh cpu-usage ram-usage gpu-usage battery"
          set -g @dracula-show-left-icon hostname
          set -g @dracula-git-show-current-symbol ✓
          set -g @dracula-git-no-repo-message "no-git"
          set -g @dracula-show-timezone false
          set -g @dracula-ignore-lspci true
        '';
      }
    ];
    extraConfig = ''
      # Automatically renumber windows
      set -g renumber-windows on
      set -g allow-passthrough on
    '';
  };
}
