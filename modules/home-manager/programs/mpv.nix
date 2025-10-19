{ lib, ... }:
{
  programs.mpv = {
    enable = lib.mkDefault false;
    config = {
      hwdec = "auto";
      vo = "gpu";
    };
  };
}
