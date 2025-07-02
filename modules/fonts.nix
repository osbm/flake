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
      fonts = {
    packages =
      builtins.attrValues {
        inherit
          (pkgs)
          material-icons
          material-design-icons
          roboto
          work-sans
          comic-neue
          source-sans
          twemoji-color-font
          comfortaa
          inter
          lato
          lexend
          jost
          dejavu_fonts
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-emoji
          ;
      }
      ++ [
        pkgs.nerd-fonts.jetbrains-mono
        # (pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];})
      ];

    enableDefaultPackages = false;

    # this fixes emoji stuff
    fontconfig = {
      defaultFonts = {
        monospace = [
          "JetBrainsMono"
          "JetBrainsMono Nerd Font"
          "Noto Color Emoji"
        ];
        sansSerif = ["Lexend" "Noto Color Emoji"];
        serif = ["Noto Serif" "Noto Color Emoji"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
    })
  ];
}
