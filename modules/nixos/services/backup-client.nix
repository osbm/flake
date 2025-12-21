# Backup client - pulls backups from remote servers via rsync
# Supports full backups and selective service backups over Tailscale
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.osbmModules.services.backup-client;

  # Create a backup job for each configured backup
  makeBackupService =
    name: backupCfg:
    let
      # Build rsync paths based on what we're backing up
      sourcePaths =
        if backupCfg.fullBackup then
          [ "/persist" ] # Full backup of everything
        else if backupCfg.services != [ ] then
          # Selective service backups
          map (service: "/persist/var/lib/${service}") backupCfg.services
          ++ lib.optional (builtins.elem "vaultwarden" backupCfg.services) "/persist/backup/vaultwarden"
        else
          [ ]; # Empty list if nothing to backup

      # Rsync command for each source path
      rsyncCommands = map (source: ''
        echo "Backing up ${source} from ${backupCfg.remoteHost}..."
        ${pkgs.rsync}/bin/rsync -avz --delete \
          -e "${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
          ${backupCfg.remoteUser}@${backupCfg.remoteHost}:${source}/ \
          ${backupCfg.localPath}/${builtins.baseNameOf source}/
      '') sourcePaths;
    in
    {
      description = "Backup ${name} from ${backupCfg.remoteHost}";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      script = ''
        set -e

        # Create backup directory if it doesn't exist
        mkdir -p ${backupCfg.localPath}

        # Run rsync for each source path
        ${lib.concatStringsSep "\n" rsyncCommands}

        echo "Backup ${name} completed successfully at $(date)"
      '';
    };

  makeBackupTimer = name: backupCfg: {
    description = "Timer for ${name} backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = backupCfg.schedule;
      Persistent = true;
      RandomizedDelaySec = "30m"; # Randomize to avoid all backups running at once
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    # Create systemd services for each backup
    systemd.services = lib.mapAttrs' (
      name: backupCfg: lib.nameValuePair "backup-${name}" (makeBackupService name backupCfg)
    ) cfg.backups;

    # Create systemd timers for each backup
    systemd.timers = lib.mapAttrs' (
      name: backupCfg: lib.nameValuePair "backup-${name}" (makeBackupTimer name backupCfg)
    ) cfg.backups;

    # Ensure rsync and openssh are available
    environment.systemPackages = with pkgs; [
      rsync
      openssh
    ];

    # Ensure Tailscale is enabled for secure connections
    assertions = [
      {
        assertion = config.services.tailscale.enable;
        message = "backup-client requires Tailscale to be enabled for secure connections";
      }
    ];
  };
}
