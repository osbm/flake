{
  programs.direnv = {
    enable = true;
    # enableFishIntegration = true; # why add a read-only option?
    nix-direnv.enable = true;
  };
}
