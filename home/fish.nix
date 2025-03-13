{
  programs.fish = {
    enable = true;
    shellAliases = {
      c = "code .";
      l = "ls -lah";
      free = "free -h";
      df = "df -h";
      du = "du -h";
    };
  };
}