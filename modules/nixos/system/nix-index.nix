{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  isDarwin = pkgs.stdenv.isDarwin;
  nixIndexModule =
    if isDarwin then
      inputs.nix-index-database.darwinModules.nix-index
    else
      inputs.nix-index-database.nixosModules.nix-index;
in
{
  imports = [
    nixIndexModule
  ];

  config = lib.mkIf (config.osbmModules.nixIndex.enable && inputs ? nix-index-database) {
    programs.nix-index-database.comma.enable = true;
    programs.command-not-found.enable = lib.mkIf (!isDarwin) false;
  };
}
