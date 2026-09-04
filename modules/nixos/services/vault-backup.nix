{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.osbmModules.services.vault-backup;

  # apollo is the vault's SOLE git committer: syncthing moves files between
  # devices, this timer turns the synced tree into history on forgejo.
  # Other machines must not run git in the vault (their .git dirs are removed).
  backupScript = pkgs.writeShellScript "vault-backup" ''
    set -eu
    cd ${cfg.path}
    ${pkgs.git}/bin/git add -A
    if ${pkgs.git}/bin/git diff --cached --quiet; then
      echo "vault clean, nothing to commit"
      exit 0
    fi
    NUM=$(${pkgs.git}/bin/git diff --cached --name-only | wc -l)
    ${pkgs.git}/bin/git commit -m "vault backup: $(date '+%Y-%m-%d %H:%M:%S') device: $(hostname) num files: $NUM"
    ${pkgs.git}/bin/git push origin main
  '';
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.vault-backup = {
      description = "Commit and push the synced vault to forgejo";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "osbm";
        ExecStart = backupScript;
      };
    };

    systemd.timers.vault-backup = {
      description = "Nightly vault backup commit";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
      };
    };
  };
}
