{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true;
    statix.enable = true;
    shellcheck.enable = true;
    deadnix.enable = true;
  };
  settings = {
    global.excludes = [
      "*.lock"
    ];
  };
}
