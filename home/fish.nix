{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    shellAliases = {
      c = "code .";
      l = "ls -lah";
      free = "free -h";
      df = "df -h";
      du = "du -h";
      lg = "lazygit";
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