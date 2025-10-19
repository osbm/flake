{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.osbmModules.fonts.enable {
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
      jetbrains-mono
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "JetBrainsMono"
          "Iosevka"
        ];
      })
    ];

    fonts.fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [
          "JetBrainsMono Nerd Font"
          "Fira Code"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
