{ lib, nixosConfig, ... }:
{
  config = lib.mkMerge [
    (lib.mkIf (nixosConfig != null && nixosConfig.osbmModules.desktopEnvironment != "none") {
      # Set enableGhostty to true by default when there's a desktop environment
      programs.ghostty.enable = lib.mkDefault true;
    })
  ];
}
