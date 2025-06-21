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
        
      '';
    };
  };
}
