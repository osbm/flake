{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    shellAliases = {
      c = "code .";
      l = "eza --all --long --git --icons --group --sort size --header --group-directories-first";
      ll = "eza --all --long --git --icons --group --sort name --header --group-directories-first";
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
