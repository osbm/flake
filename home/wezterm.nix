{
  lib,
  config,
  ...
}: {
  options.enableWezterm = lib.mkEnableOption "Wezterm terminal emulator";
  config = {
    programs.wezterm = {
      enable = config.enableWezterm;
      extraConfig = ''
        _G.shells = {
          fish = ${lib.getExe pkgs.fish}
        };

        local cfg = require('config');
        return cfg
      '';
    };
  };
}
