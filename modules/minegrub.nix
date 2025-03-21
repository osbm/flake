{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.minegrub-theme.nixosModules.default
  ];
  options = {
    myModules.enableMinegrubTheme = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Minecraft theme for grub.";
    };
  };
  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableMinegrubTheme {
      boot.loader.grub = {
        minegrub-theme = {
          enable = true;
          splash = "100% Flakes!";
          background = "background_options/1.8  - [Classic Minecraft].png";
          boot-options-count = 4;
        };
      };
    })
  ];
}
