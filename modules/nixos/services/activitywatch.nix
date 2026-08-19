{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.osbmModules.services.activitywatch;
in
{
  config = lib.mkIf cfg.enable {
    # central ActivityWatch collection point: watchers on the desktops (ymir)
    # report here so screen-time data from every machine lands in one place.
    # aw-server has NO auth of its own — never expose it beyond the tailnet.
    users.users.activitywatch = {
      isSystemUser = true;
      group = "activitywatch";
      home = "/var/lib/activitywatch";
      createHome = true;
    };
    users.groups.activitywatch = { };

    systemd.services.aw-server = {
      description = "ActivityWatch server (central collector)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment.HOME = "/var/lib/activitywatch";
      serviceConfig = {
        User = "activitywatch";
        Group = "activitywatch";
        ExecStart = "${pkgs.aw-server-rust}/bin/aw-server";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/activitywatch" ];
        PrivateTmp = true;
      };
    };

    # tailnet-only web UI + API: aw.osbm.dev (same belt-and-suspenders as
    # hledger — apollo has a public IP, so the vhost rejects non-tailnet
    # sources even though DNS only resolves on the tailnet)
    services.nginx.virtualHosts."aw.osbm.dev" = lib.mkIf config.osbmModules.services.nginx.enable {
      forceSSL = true;
      useACMEHost = "osbm.dev";
      locations."/" = {
        # aw-server-rust default port
        proxyPass = "http://127.0.0.1:5600";
        extraConfig = ''
          allow 100.64.0.0/10;
          allow fd7a:115c:a1e0::/48;
          deny all;
          # aw-server rejects non-localhost Host headers (DNS-rebinding
          # protection) — the tailnet-only vhost provides the real guard
          proxy_set_header Host "localhost:5600";
        '';
      };
    };

    # screen-time history is the whole point — don't lose it on reboot
    environment.persistence."/persist" =
      lib.mkIf config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
        {
          directories = [
            {
              directory = "/var/lib/activitywatch";
              user = "activitywatch";
              group = "activitywatch";
              mode = "0750";
            }
          ];
        };
  };
}
