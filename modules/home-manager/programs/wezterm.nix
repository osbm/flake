{
  lib,
  pkgs,
  nixosConfig,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf (nixosConfig != null && !nixosConfig.osbmModules.desktopEnvironment.none) {
      programs.wezterm.enable = lib.mkDefault true;
    })

    {
      programs.wezterm = {
        extraConfig = ''
          _G.shells = {
            fish = '${lib.getExe pkgs.fish}'
          };

          wezterm.on('gui-startup', function(cmd)
            local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
            window:gui_window():maximize()
          end)


          return {
            default_prog = { _G.shells.fish },
            window_decorations = "NONE",
            hide_tab_bar_if_only_one_tab = true,
            enable_wayland = false,
          }
        '';
      };
    }
  ];
}
