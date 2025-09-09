{
  pkgs,
  lib,
  config,
  ...
}:
{
  options = {
    # Enable the GTK theme
    enableGTK = lib.mkEnableOption "enableGTK";
  };

  config = lib.mkIf config.enableGTK {
    home.pointerCursor = {
      name = "Dracula";
      package = pkgs.dracula-theme;
      gtk.enable = true;
    };
    gtk = {
      enable = true;
      theme = {
        name = "Dracula";
        package = pkgs.dracula-theme;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-cursor-theme-size = 8;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-cursor-theme-size = 8;
      };
    };
  };
}
