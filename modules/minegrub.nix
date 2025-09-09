{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # imports = [
  #   inputs.minegrub-theme.nixosModules.default
  # ];
  options = {
    myModules.enableMinegrubTheme = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Minecraft theme for grub.";
    };
  };
  config = lib.mkIf config.myModules.enableMinegrubTheme {
    boot.loader.grub = {
      # minegrub-theme = {
      #   enable = true;
      #   splash = "100% Flakes!";
      #   background = "background_options/1.8  - [Classic Minecraft].png";
      #   boot-options-count = 4;
      # };
      theme = pkgs.fetchFromGitHub {
        owner = "Lxtharia";
        repo = "minegrub-theme";
        rev = "193b3a7c3d432f8c6af10adfb465b781091f56b3";
        sha256 = "1bvkfmjzbk7pfisvmyw5gjmcqj9dab7gwd5nmvi8gs4vk72bl2ap";
      };
    };
  };
}
