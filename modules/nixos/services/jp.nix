{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.osbmModules.services.jp;
  home = "/var/lib/jp";

  # one definition of the runtime for all three writers (the service, osbm's
  # CLI, hermes): `jp-run <cmd>` gives the same python, uv cache and umask.
  # uv resolves whatever the app's pyproject asks for into ${home} at start —
  # nothing python-side lives in the nix store, so new deps never need a
  # flake commit and nix GC never eats them.
  jp-run = pkgs.writeShellApplication {
    name = "jp-run";
    runtimeInputs = with pkgs; [
      uv
      python3
      git
      sqlite
      ffmpeg-headless
      curl
      coreutils
      bash
    ];
    text = ''
      # no ACLs on the ZFS root (acltype=off): group-write has to come from
      # every writer's umask
      umask 0007
      export JP_HOME=${home}
      export JP_PORT=${toString cfg.port}
      export UV_CACHE_DIR=${home}/.cache/uv
      # uv's own python downloads are generic-linux binaries; pin the nix one
      export UV_PYTHON=${pkgs.python3}/bin/python3
      export UV_PYTHON_DOWNLOADS=never
      # manylinux wheels (numpy & co) dlopen these from the nix python
      export LD_LIBRARY_PATH=${
        lib.makeLibraryPath [
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
        ]
      }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      export PYTHONUNBUFFERED=1
      exec "$@"
    '';
  };
in
{
  config = lib.mkMerge [
    # jp.osbm.dev: osbm's japanese study app. The flake owns only this frame
    # (user, dir, unit, vhost); everything inside ${home} — code, UI, sqlite
    # db, python deps — is mutable and maintained by the agents (Claude CLI as
    # osbm, hermes) without touching the flake.
    (lib.mkIf cfg.enable {
      users.users.jp = {
        isSystemUser = true;
        group = "jp";
        inherit home;
      };
      users.groups.jp = { };
      users.users.${config.osbmModules.defaultUser}.extraGroups = [ "jp" ];

      environment.systemPackages = [
        jp-run
        pkgs.uv
      ];

      # setgid + group-write: the jp group (service, osbm, hermes) shares it
      systemd.tmpfiles.rules = [
        "d ${home} 2770 jp jp -"
        "d ${home}/app 2770 jp jp -"
        "d ${home}/data 2770 jp jp -"
        "d ${home}/log 2770 jp jp -"
        # pre-created so the unit's append: target is jp-owned (systemd would
        # otherwise create it root 0644 and nobody could rotate it)
        "f ${home}/log/jp.log 0660 jp jp -"
        "f ${home}/restart 0660 jp jp -"
      ];

      systemd.services.jp = {
        description = "jp.osbm.dev study app (agent-maintained, see ${home}/app)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        # the entry point is the agents' to define; idle until it exists
        unitConfig.ConditionPathExists = "${home}/app/run.sh";
        # agents restart this at will — never trip the start limit
        unitConfig.StartLimitIntervalSec = 0;
        environment.HOME = home;
        serviceConfig = {
          User = "jp";
          Group = "jp";
          WorkingDirectory = "${home}/app";
          ExecStart = "${lib.getExe jp-run} bash ${home}/app/run.sh";
          Restart = "on-failure";
          RestartSec = 10;
          UMask = "0007";
          # hermes can't read the journal, so log where the group can
          StandardOutput = "append:${home}/log/jp.log";
          StandardError = "append:${home}/log/jp.log";

          # wild changes welcome, but only in here
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ home ];
          PrivateTmp = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          LockPersonality = true;
          CapabilityBoundingSet = "";
        };
      };

      # sudo-free restart for the agents: `touch ${home}/restart`
      # (same-named path unit triggers the service; works from inside
      # hermes's sandbox, no polkit)
      systemd.paths.jp-restart = {
        wantedBy = [ "paths.target" ];
        pathConfig.PathChanged = "${home}/restart";
      };
      systemd.services.jp-restart = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl restart jp.service";
        };
        unitConfig.StartLimitIntervalSec = 0;
      };

      # three writers with three default modes (see hermes-commons-janitor):
      # keep the tree group-rw so none of them locks the others out
      systemd.services.jp-janitor = {
        script = ''
          find ${home} -type d ! -perm -2770 -exec chmod ug+rwx,g+s {} + 2>/dev/null || true
          find ${home} -type f ! -perm -0660 -exec chmod ug+rw {} + 2>/dev/null || true
          find ${home} ! -group jp -exec chgrp -h jp {} + 2>/dev/null || true
        '';
        serviceConfig.Type = "oneshot";
      };
      systemd.timers.jp-janitor = {
        wantedBy = [ "timers.target" ];
        timerConfig.OnBootSec = "2min";
        timerConfig.OnUnitActiveSec = "5min";
      };

      # lets binaries fetched at runtime (wheels that ship executables, static
      # tools) run without a nix wrapper
      programs.nix-ld.enable = true;
    })

    # hermes seat: same full access as osbm's CLI
    (lib.mkIf (cfg.enable && config.osbmModules.services.hermes.enable) {
      users.users.hermes.extraGroups = [ "jp" ];
      systemd.services.hermes-agent.serviceConfig.ReadWritePaths = [ home ];
      systemd.services.hermes-agent.serviceConfig.UMask = "0007";
    })
    (lib.mkIf
      (
        cfg.enable && config.osbmModules.services.hermes.enable && config.osbmModules.services.nginx.enable
      )
      {
        systemd.services.hermes-web.serviceConfig.ReadWritePaths = [ home ];
        systemd.services.hermes-webui.serviceConfig.ReadWritePaths = [ home ];
      }
    )

    # tailnet-only, no auth: reachability already implies one of osbm's
    # devices (same guard as aw/hledger — apollo has a public IP)
    (lib.mkIf (cfg.enable && config.osbmModules.services.nginx.enable) {
      services.nginx.virtualHosts."jp.osbm.dev" = {
        forceSSL = true;
        useACMEHost = "osbm.dev";
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          proxyWebsockets = true;
          extraConfig = ''
            allow 100.64.0.0/10;
            allow fd7a:115c:a1e0::/48;
            deny all;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            # audio streams + server-sent events
            proxy_buffering off;
            proxy_read_timeout 1h;
            client_max_body_size 100m;
          '';
        };
      };
    })

    # impermanence: study history is the whole point
    (lib.mkIf (cfg.enable && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot) {
      environment.persistence."/persist" = {
        directories = [
          {
            directory = home;
            user = "jp";
            group = "jp";
            mode = "2770";
          }
        ];
      };
    })
  ];
}
