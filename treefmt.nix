{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt-rfc-style;
    };
    statix.enable = true;
    shellcheck.enable = true;
    deadnix.enable = true;
  };
}
