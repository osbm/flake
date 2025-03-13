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
    };
  };
}