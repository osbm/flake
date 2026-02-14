{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.osbmModules.services.healthcheck;

  healthcheckScript = pkgs.writeShellScript "healthcheck" ''
    STATE_FILE="/var/lib/healthcheck/failure_count"
    mkdir -p /var/lib/healthcheck

    if ! [ -f "$STATE_FILE" ]; then
      echo 0 > "$STATE_FILE"
    fi

    FAILURES=$(cat "$STATE_FILE")

    if ${pkgs.curl}/bin/curl -sf --max-time 10 "${cfg.target}" > /dev/null 2>&1; then
      echo 0 > "$STATE_FILE"
    else
      FAILURES=$((FAILURES + 1))
      echo "$FAILURES" > "$STATE_FILE"

      if [ "$FAILURES" -ge 3 ]; then
        ${pkgs.curl}/bin/curl -sf \
          -H "Title: Machine Down Alert" \
          -H "Priority: urgent" \
          -H "Tags: warning" \
          -d "Target ${cfg.target} has been unreachable for $FAILURES consecutive checks." \
          "${cfg.ntfyUrl}/alerts" || true
      fi
    fi
  '';
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.healthcheck = {
      description = "Health check for remote machine";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = healthcheckScript;
        StateDirectory = "healthcheck";
      };
    };

    systemd.timers.healthcheck = {
      description = "Run health check every 2 minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "2min";
        Unit = "healthcheck.service";
      };
    };
  };
}
