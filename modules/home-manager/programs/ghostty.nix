{ lib, ... }:
{
  programs.ghostty = {
    enable = lib.mkDefault false;
    # Configuration can be added as needed
  };
}
