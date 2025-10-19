{ lib, ... }:
{
  programs.alacritty = {
    enable = lib.mkDefault false;
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
