{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      dart.disabled = true;
      python.disabled = true;
      nodejs.disabled = true;
      c.disabled = true;
      gradle.disabled = true;
      java.disabled = true;
      ruby.disabled = true;
      rust.disabled = true;
      typst.disabled = true;
    };
  };
}
