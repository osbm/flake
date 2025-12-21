# Backup server - exposes data for backup clients to pull
# Enables ZFS snapshots for local point-in-time recovery
{
  config,
  lib,
  ...
}:
let
  cfg = config.osbmModules.services.backup-server;
in
{
  config = lib.mkIf cfg.enable {
    # Enable ZFS auto-snapshots if requested
    services.zfs.autoSnapshot = lib.mkIf cfg.zfsSnapshots.enable {
      enable = true;
      inherit (cfg.zfsSnapshots)
        frequent
        hourly
        daily
        weekly
        monthly
        ;
    };

    # Allow root SSH login for backup clients to pull data
    # Note: Root's authorized keys are already configured in system/users.nix
    services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";

    # Ensure SSH is enabled for backup access
    assertions = [
      {
        assertion = config.services.openssh.enable;
        message = "backup-server requires openssh to be enabled";
      }
    ];
  };
}
