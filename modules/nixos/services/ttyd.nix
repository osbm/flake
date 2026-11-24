{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.osbmModules.services.ttyd;
  port = 7681;
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.ttyd = {
      description = "ttyd browser terminal (tailnet only)";
      after = [
        "network-online.target"
        "tailscaled.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        "/run/current-system/sw"
        "/etc/profiles/per-user/${config.osbmModules.defaultUser}"
      ];
      serviceConfig = {
        User = config.osbmModules.defaultUser;
        WorkingDirectory = "~";
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.ttyd}/bin/ttyd"
          "--port ${toString port}"
          "--interface tailscale0"
          "--writable"
          "--max-clients 4"
          "--client-option fontSize=14"
          # Nerd Font glyphs for yazi/eza icons; served as webfonts by apollo's nginx (services/nginx.nix)
          "--client-option \"fontFamily='FiraCode Nerd Font Mono', 'Symbols Nerd Font Mono', 'Noto Sans Symbols 2', monospace\""
          "--client-option disableLeaveAlert=true"
          # browser tab title = hostname, so apollo/ymir/... tabs are distinguishable
          "--client-option titleFixed=${config.networking.hostName}"
          # sixel images (yazi previews etc.); tmux is built with sixel and passes them through
          "--client-option enableSixel=true"
          # macOS: Option+drag selects natively (bypasses tmux mouse mode) so ttyd copies on select
          "--client-option macOptionClickForcesSelection=true"
          "${pkgs.tmux}/bin/tmux new-session -A -s web"
        ];
        Restart = "always";
        RestartSec = 5;
      };
    };
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
  };
}
