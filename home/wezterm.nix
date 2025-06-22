{
  lib,
  config,
  pkgs,
  ...
}: {
  options.enableWezterm = lib.mkEnableOption "Wezterm terminal emulator";
  config = {
    programs.wezterm = {
      enable = config.enableWezterm;
      extraConfig = ''
        _G.shells = {
          fish = '${lib.getExe pkgs.fish}'
        };
        return {
          default_prog = { _G.shells.fish },
        }
      '';
    };
  };
}
