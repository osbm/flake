{
  lib,
  pkgs,
  nixosConfig,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf (nixosConfig != null && !nixosConfig.osbmModules.desktopEnvironment.none) {
      # Set enableAlacritty to true by default when there's a desktop environment
      programs.alacritty.enable = lib.mkDefault true;
    })

    {
      programs.alacritty = {
        settings = {
          font = {
            size = 14.0;
            normal.family = "Cascadia Code";
          };
          terminal.shell = {
            args = [
              "new-session"
              "-A"
              "-s"
              "general"
            ];
            program = lib.getExe pkgs.tmux;
          };
          window = {
            decorations = "None";
            opacity = 1;
            startup_mode = "Maximized";
          };
          env.TERM = "xterm-256color";
        };
      };
    }
  ];
}
