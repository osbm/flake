{ lib, config, inputs, ... }:
{
  config = lib.mkIf (config.osbmModules.nixIndex.enable && inputs ? nix-index-database) {
    programs.nix-index-database.comma.enable = true;
    programs.command-not-found.enable = false;
  };
}
