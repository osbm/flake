{ inputs, ... }:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];
  programs.nix-index-database.comma.enable = true;
  programs.command-not-found.enable = false; # TODO fix ts

}
