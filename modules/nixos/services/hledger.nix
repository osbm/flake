{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.osbmModules.services.hledger;
  journal = "/var/lib/hledger-web/main.journal";
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.hledger-web = {
        enable = true;
        # view + add transactions from the browser; journal file editing
        # stays off the web surface (hermes/CLI edit it directly instead)
        allow = "add";
        journalFiles = [ "main.journal" ];
        baseUrl = "https://hledger.osbm.dev";
      };

      # the module only creates the state dir, not the journal itself, and
      # hledger-web refuses to start on a missing file. setgid + group-write
      # so the hledger group (hermes, main user) can append and new files
      # inherit the group
      systemd.tmpfiles.rules = [
        "d /var/lib/hledger-web 2770 hledger hledger -"
        "f ${journal} 0660 hledger hledger -"
        # default ACL: files created later (by hermes, the web UI, or the
        # main user) are group-writable regardless of the creator's umask —
        # every group member keeps full access to everything, always.
        # (plain rwx, not rwX — tmpfiles can't parse the conditional bit in
        # ACLs; the create-mode mask keeps the x off files anyway)
        "a+ /var/lib/hledger-web - - - - d:g:hledger:rwx"
      ];

      # keep files created by the web UI group-writable
      systemd.services.hledger-web.serviceConfig.UMask = "0007";
      # upstream sets StateDirectory=hledger-web, and systemd resets the dir
      # to StateDirectoryMode on every start — without this it clobbers the
      # tmpfiles 2770 back to 0755 and locks the hledger group out
      systemd.services.hledger-web.serviceConfig.StateDirectoryMode = "2770";

      # hledger CLI for interactive use against the same journal
      environment.systemPackages = [ pkgs.hledger ];
      environment.variables.LEDGER_FILE = journal;

      # let the main user inspect/edit the journal directly
      users.users.${config.osbmModules.defaultUser}.extraGroups = [ "hledger" ];
    })

    # hermes seat: the agent reads and appends transactions and runs reports
    # through the hledger CLI, same journal the web UI serves. Full group
    # access — the separation from /var/lib/hermes only restricts what
    # hledger-web can see, never the agent
    (lib.mkIf (cfg.enable && config.osbmModules.services.hermes.enable) {
      users.users.hermes.extraGroups = [ "hledger" ];

      # make the finance dir visible from the agent's workspace so it finds
      # the books by just looking around
      systemd.tmpfiles.rules = [
        "L /var/lib/hermes/workspace/finance - - - - /var/lib/hledger-web"
      ];

      systemd.services.hermes-agent = {
        # hledger is already in systemPackages (survives the login-shell
        # PATH reset, see the anki block in hermes.nix); unit path for
        # non-shell spawns
        path = [ pkgs.hledger ];
        environment.LEDGER_FILE = journal;
        # upstream unit confines writes to /var/lib/hermes; widen for the journal
        serviceConfig.ReadWritePaths = [ "/var/lib/hledger-web" ];
      };
    })

    # web UI behind nginx, reachable only over tailscale: hledger.osbm.dev
    # resolves to apollo's tailnet IP, and the vhost additionally rejects
    # non-tailnet sources in case the public IP is hit directly with a
    # matching SNI (finance data — same belt-and-suspenders as the hermes
    # dashboard)
    (lib.mkIf (cfg.enable && config.osbmModules.services.nginx.enable) {
      services.nginx.virtualHosts."hledger.osbm.dev" = {
        forceSSL = true;
        useACMEHost = "osbm.dev";
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.hledger-web.port}";
          extraConfig = ''
            allow 100.64.0.0/10;
            allow fd7a:115c:a1e0::/48;
            deny all;
          '';
        };
      };
    })

    # impermanence: the journal is the single source of truth — losing it on
    # reboot would be losing the books
    (lib.mkIf (cfg.enable && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot) {
      environment.persistence."/persist" = {
        directories = [
          {
            directory = "/var/lib/hledger-web";
            user = "hledger";
            group = "hledger";
            mode = "0770";
          }
        ];
      };
    })
  ];
}
