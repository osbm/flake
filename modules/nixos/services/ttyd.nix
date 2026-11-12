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
          "--client-option disableLeaveAlert=true"
          "${pkgs.tmux}/bin/tmux new-session -A -s web"
        ];
        Restart = "always";
        RestartSec = 5;
      };
    };
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
  };
}
