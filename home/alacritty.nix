{pkgs, lib, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        size = 17.0;
        normal.family = "Cascadia Code";
      };
      terminal.shell = {
        args = ["new-session" "-A" "-s" "general"];
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
