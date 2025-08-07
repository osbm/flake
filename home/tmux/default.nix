{
  pkgs,
  lib,
  ...
}:
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
        plugin = tmuxPlugins.dracula;
        extraConfig = ''
          set -g @dracula-plugins "cpu-usage ram-usage gpu-usage battery"
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
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
    '';
  };
}
