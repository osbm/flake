{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    functions = {
      gitu = ''
        git add --all
        git commit -m "$argv"
        git push
      '';
    };
  };
}
