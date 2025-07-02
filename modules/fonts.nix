{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    myModules.enableFonts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable my favorite fonts";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableFonts {
      fonts.packages = with pkgs; [
        cascadia-code
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
        mplus-outline-fonts.githubRelease
        dina-font
        nerd-fonts.fira-code
        nerd-fonts.ubuntu
        nerd-fonts.droid-sans-mono
        proggyfonts
        source-sans
        source-han-sans
        source-han-mono
        source-sans-pro
        source-serif-pro
        font-awesome
        font-awesome_5
        roboto
        twitter-color-emoji
        iosevka
      ];
      # fonts.fontconfig = {
      #   defaultFonts.emoji = ["Noto Color Emoji"];
      # };
      fonts.fontconfig.defaultFonts = {
        serif = ["Source Han Serif SC" "Source Han Serif TC" "Noto Color Emoji"];
        sansSerif = ["Source Han Sans SC" "Source Han Sans TC" "Noto Color Emoji"];
        monospace = ["Droid Sans Mono" "Source Han Mono" "Cascadia Code" "Noto Color Emoji"];
        emoji = ["Noto Color Emoji"];
      };
    })
  ];
}
