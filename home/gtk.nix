{pkgs, ...}: {
  gtk = {
    enable = true;
    theme = {
      name = "Dracula";
      package = pkgs.dracula-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-size=8;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-size=8;
    };
  };
}
