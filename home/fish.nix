{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    shellAliases = {
      c = "code .";
      l = "ls -lah";
      ll = "eza -la -F --icons --git --group-directories-first --git";
      free = "free -h";
      df = "df -h";
      du = "du -h";
      lg = "lazygit";
      onefetch = "onefetch -T prose -T programming -T data";
    };
    functions = {
      gitu = ''
        git add --all
        git commit -m "$argv"
        git push
      '';
    };
  };
}
