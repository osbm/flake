{ lib, config, inputs, ... }:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];

  config = lib.mkIf (config.osbmModules.nixIndex.enable && inputs ? nix-index-database) {
    programs.nix-index-database.comma.enable = true;
    programs.command-not-found.enable = false;
  };
}
