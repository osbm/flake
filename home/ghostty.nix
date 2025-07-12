{
  lib,
  config,
  ...
}:
{
  options.enableGhostty = lib.mkEnableOption "Ghostty terminal emulator";
  config = {
    programs.ghostty = {
      enable = config.enableGhostty;
      settings = {
      };
    };
  };
}
