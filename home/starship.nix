{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      dart.disabled = true;
      python.disabled = true;
      nodejs.disabled = true;
    };
  };
}