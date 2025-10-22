{ lib, nixosConfig, ... }:
{
  config = lib.mkMerge [
    (lib.mkIf (nixosConfig != null && nixosConfig.osbmModules.desktopEnvironment != "none") {
      # Set enableAlacritty to true by default when there's a desktop environment
      programs.alacritty.enable = lib.mkDefault true;
    })

    {
      programs.alacritty = {
        settings = {
          window = {
            opacity = 0.95;
            padding = {
              x = 10;
              y = 10;
            };
          };
          font = {
            size = 11.0;
          };
        };
      };
    }
  ];
}
