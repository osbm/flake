{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      font.size = 12.0;
      terminal.shell = {
        args = ["new-session" "-A" "-s" "general"];
        program = pkgs.tmux + "/bin/tmux";
      };
      window = {
        decorations = "None";
        opacity = 1;
        startup_mode = "Maximized";
      };
    };
  };
}
