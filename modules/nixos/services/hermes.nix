{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.osbmModules.services.hermes;
  # python for hermes skill scripts: stdlib (duolingo) + caldav (radicale)
  hermes-python = pkgs.python3.withPackages (ps: [ ps.caldav ]);
  # plain python3 with the anki lib's vendored site-packages on PYTHONPATH.
  # pkgs.anki's "lib" output bundles every python dep, so this stays headless —
  # no Qt/webengine closure like `toPythonModule pkgs.anki` would drag in.
  anki-python = pkgs.writeShellScriptBin "anki-python" ''
    export PYTHONPATH="${pkgs.anki.lib}/lib/${pkgs.python3.libPrefix}/site-packages''${PYTHONPATH:+:$PYTHONPATH}"
    exec ${pkgs.python3}/bin/python3 "$@"
  '';
in
{
  imports = [
    inputs.hermes-agent.nixosModules.default
    inputs.hermes-webui.nixosModules.default
  ];

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.hermes-agent = {
        enable = true;
        # hermes CLI/TUI/dashboard for interactive use, shares the service HERMES_HOME
        addToSystemPackages = true;
        environmentFiles = [
          config.age.secrets.hermes-env.path
          # DUOLINGO_JWT / _USERNAME / _USER_ID for the duolingo skill;
          # the browser-cookie JWT effectively never expires (exp year 2169)
          config.age.secrets.duolingo-env.path
          # CALDAV_* for the calendar skill (radicale user "hermes":
          # read on osbm's collections, write on osbm/hermes-agenda)
          config.age.secrets.radicale-hermes-env.path
          # DEEPSEEK_API_KEY for the deepseek fallback_model entry below —
          # a separate provider so it survives full Anthropic-pool exhaustion
          # (haiku can't, it shares the subscription bucket)
          config.age.secrets.deepseek-env.path
        ];
        # Claude Max subscription via `hermes login anthropic` (auth.json);
        # nix-managed keys win over TUI edits on every activation
        settings = {
          # dict form with an explicit provider: since hermes 0.20.0 (#29285),
          # exported API keys outrank the OAuth login in provider auto-detection,
          # so a bare model string let DEEPSEEK_API_KEY (loaded for the fallback
          # below) hijack every new session onto deepseek. `provider` pins the
          # primary to the Max subscription; `default` is the canonical model-id
          # key ("model"/"name" are legacy aliases).
          model = {
            provider = "anthropic";
            default = "claude-opus-4-8";
          };
          # fallback chain, tried in order when the subscription pool is
          # throttled/exhausted
          # haiku shares the subscription pool but has its own rate-limit
          # bucket, so it keeps telegram alive when sonnet/opus are throttled
          fallback_model = [
            {
              provider = "anthropic";
              model = "claude-haiku-4-5";
            }
            # separate provider (own API key + balance), so it keeps chat AND
            # cron alive when the whole Anthropic subscription pool is
            # exhausted — the case haiku above can't cover. deepseek-chat /
            # deepseek-reasoner are retired; the API only accepts v4-pro/v4-flash.
            {
              provider = "deepseek";
              model = "deepseek-v4-pro";
            }
            # {
            #   provider = "gemini";
            #   model = "gemini-3.1-pro-preview";
            # }
          ];
        };
      };

      age.secrets.hermes-env.file = ../../../secrets/hermes-env.age;
      age.secrets.deepseek-env.file = ../../../secrets/deepseek-env.age;
      age.secrets.duolingo-env.file = ../../../secrets/duolingo-env.age;
      age.secrets.radicale-hermes-env.file = ../../../secrets/radicale-hermes-env.age;

      # let the main user run `hermes` against the service state
      users.users.${config.osbmModules.defaultUser}.extraGroups = [
        "hermes"
        # read `journalctl -u hermes-agent` without sudo — needed to diagnose
        # runtime events like the .hermes chmod-to-0700 incident (2026-08-18)
        "systemd-journal"
      ];

      # shared-brain seat: the Claude Code CLI (running as the main user, who
      # is in the hermes group) reads the same skills, persona and memories
      # the agent uses — two front-ends onto one brain.
      #
      # Layout: the shared files live in /var/lib/hermes/shared
      # (group-writable); symlinks inside .hermes point there so hermes finds
      # everything at its usual paths. The den itself is ALSO group-accessible
      # (2770, osbm's decision 2026-08-31: both agents get the same view) —
      # only auth.json stays 0600, hermes-private. The janitor below keeps it
      # that way at runtime.
      systemd.tmpfiles.rules = [
        "d /var/lib/hermes/.hermes 2770 hermes hermes -"
        "d /var/lib/hermes/shared 2770 hermes hermes -"
        "d /var/lib/hermes/shared/memories 2770 hermes hermes -"
        "d /var/lib/hermes/shared/skills 2770 hermes hermes -"
        "L /var/lib/hermes/.hermes/memories - - - - /var/lib/hermes/shared/memories"
        "L /var/lib/hermes/.hermes/skills - - - - /var/lib/hermes/shared/skills"
        "L /var/lib/hermes/.hermes/SOUL.md - - - - /var/lib/hermes/shared/SOUL.md"
      ];

      # commons janitor: two agents (hermes + osbm's CLI) write with
      # different default modes — hermes's memory writer makes 0600 files,
      # osbm's umask makes group-read-only ones — and the hermes harness
      # re-chmods the den to 0700 on every token write (secure_parent_dir,
      # not configurable). This makes everything group-rw again; only
      # auth.json (tokens) stays hermes-private. Runs every 15 min AND
      # whenever the den changes (path unit below). The `! -perm` guards
      # matter: chmod always emits IN_ATTRIB even when the mode is
      # unchanged, so unguarded chmods would retrigger the path unit in an
      # endless loop.
      systemd.services.hermes-commons-janitor = {
        script = ''
          find /var/lib/hermes/.hermes -maxdepth 0 \
            ! -perm 2770 -exec chmod 2770 {} + 2>/dev/null || true
          find /var/lib/hermes/shared /var/lib/hermes/workspace /var/lib/hermes/.hermes \
            -type f -not -name 'auth.json*' ! -perm -0660 -exec chmod ug+rw {} + 2>/dev/null || true
          find /var/lib/hermes/shared /var/lib/hermes/workspace /var/lib/hermes/.hermes \
            -mindepth 1 -type d ! -perm -2770 -exec chmod ug+rwx,g+s {} + 2>/dev/null || true
        '';
        serviceConfig.Type = "oneshot";
        # hermes-agent writes bursts of files into .hermes on startup; each
        # one fires the path unit, and 5 starts in 10s trips the default
        # start limit and fails BOTH units (seen on the 2026-09-01 switch).
        # The perm guards already prevent self-loops, so unlimited starts
        # of this ~50ms no-op sweep are safe.
        unitConfig.StartLimitIntervalSec = 0;
      };
      systemd.timers.hermes-commons-janitor = {
        wantedBy = [ "timers.target" ];
        timerConfig.OnBootSec = "2min";
        timerConfig.OnUnitActiveSec = "15min";
      };
      # same-named path unit implicitly triggers the janitor service:
      # inotify fires on the harness's chmod (IN_ATTRIB), restoring group
      # access moments after each token write instead of after ≤15 min.
      systemd.paths.hermes-commons-janitor = {
        wantedBy = [ "paths.target" ];
        pathConfig.PathChanged = "/var/lib/hermes/.hermes";
      };

      # python for skill scripts (duolingo, calendar); in systemPackages so
      # it also survives the login-shell PATH reset (see anki block below)
      systemd.services.hermes-agent.path = [ hermes-python ];
      environment.systemPackages = [ hermes-python ];

      # tighten the upstream unit: hide /home, drop capabilities, block
      # kernel-facing surfaces. Writes stay confined to /var/lib/hermes.
      systemd.services.hermes-agent.serviceConfig = {
        ProtectHome = lib.mkForce true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        CapabilityBoundingSet = "";
        # hermes may read the wanikani archive but never write it
        # ("-" = ignore on hosts where the path doesn't exist)
        ReadOnlyPaths = [ "-/var/lib/wanikani-logs" ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
          "AF_NETLINK"
        ];
      };
    })

    # anki client seat: when this host also runs the anki sync server, hermes
    # becomes a regular sync client (own collection copy under
    # /var/lib/hermes/anki) — it reads the revlog and creates decks through the
    # sync protocol, never touching the server's data files directly.
    # The skill lives in /var/lib/hermes/.hermes/skills/anki.
    (lib.mkIf (cfg.enable && config.osbmModules.services.anki-sync-server.enable) {
      # widen the server's password secret so the hermes user can read it too
      # (the sync server itself reads it as root via LoadCredential)
      age.secrets.anki-sync-password = {
        group = "hermes";
        mode = "0440";
      };

      # systemPackages, not just unit path: hermes's exec tool spawns login
      # shells, and /etc/set-environment resets PATH to the system profiles —
      # unit-level path additions don't survive that
      environment.systemPackages = [ anki-python ];

      systemd.services.hermes-agent = {
        path = [ anki-python ];
        environment = {
          # loopback endpoint — no need to round-trip through nginx/tailnet
          ANKI_SYNC_ENDPOINT = "http://127.0.0.1:${toString config.services.anki-sync-server.port}/";
          ANKI_SYNC_USERNAME = "osbm";
          ANKI_SYNC_PASSWORD_FILE = config.age.secrets.anki-sync-password.path;
        };
      };
    })

    # web dashboard behind nginx, reachable only over tailscale:
    # hermes.osbm.dev resolves to apollo's tailnet IP, and the vhost
    # additionally rejects non-tailnet sources in case the public IP is hit
    # directly with a matching SNI.
    (lib.mkIf (cfg.enable && config.osbmModules.services.nginx.enable) {
      age.secrets.hermes-dashboard-token.file = ../../../secrets/hermes-dashboard-token.age;

      systemd.services.hermes-web = {
        description = "Hermes Agent Web Dashboard";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "hermes-agent.service"
        ];
        wants = [ "network-online.target" ];

        environment = {
          HOME = "/var/lib/hermes";
          HERMES_HOME = "/var/lib/hermes/.hermes";
          HERMES_MANAGED = "true";
        };

        path = [
          config.services.hermes-agent.package
          pkgs.bash
          pkgs.coreutils
          pkgs.git
        ];

        serviceConfig = {
          User = "hermes";
          Group = "hermes";
          WorkingDirectory = "/var/lib/hermes/workspace";
          # pins the dashboard's loopback-mode session token so remote
          # clients (hermes desktop on ymir) can authenticate with a stable
          # credential instead of the per-restart ephemeral one
          EnvironmentFile = config.age.secrets.hermes-dashboard-token.path;
          # `serve` became a headless backend upstream; the browser UI moved
          # to the `dashboard` subcommand
          ExecStart = "${config.services.hermes-agent.package}/bin/hermes dashboard --skip-build --no-open --host 127.0.0.1 --port 9119";
          Restart = "on-failure";
          RestartSec = 5;
          UMask = "0007";

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ "/var/lib/hermes" ];
          PrivateTmp = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          LockPersonality = true;
        };
      };

      services.nginx.virtualHosts."hermes.osbm.dev" = {
        forceSSL = true;
        useACMEHost = "osbm.dev";
        locations."/" = {
          proxyPass = "http://127.0.0.1:9119";
          proxyWebsockets = true;
          extraConfig = ''
            allow 100.64.0.0/10;
            allow fd7a:115c:a1e0::/48;
            deny all;
            # dashboard is loopback-bound and rejects non-loopback Origins on
            # websocket upgrades; an empty Origin from a trusted proxy is allowed
            proxy_set_header Origin "";
          '';
        };
      };
    })

    # hermes-webui (chat.osbm.dev): mobile-first browser UI onto the same
    # brain — third front-end next to Telegram and the CLI. It runs the agent
    # IN-PROCESS against the shared HERMES_HOME (no stable agent API boundary
    # yet, so the flake pins both hermes inputs to update together; see
    # flake.nix). Running as the hermes user means it can read auth.json —
    # accepted trade-off (2026-09-01): small auditable codebase, tailnet-only
    # vhost, own password auth.
    (lib.mkIf (cfg.enable && config.osbmModules.services.nginx.enable) {
      # no password auth: the vhost is tailnet-only (and the bind loopback-only),
      # so reachability already implies it's one of osbm's devices
      services.hermes-webui = {
        enable = true;
        host = "127.0.0.1";
        port = 8787;
        # run as the agent's account so it shares the den (upstream-sanctioned
        # for co-located agents; the module then skips its own user creation)
        user = "hermes";
        group = "hermes";
        hermesHome = "/var/lib/hermes/.hermes";
        # derives HERMES_WEBUI_PYTHON from passthru.hermesVenv — same closure
        # as the running agent, so the pair can't skew on one host
        agent.package = config.services.hermes-agent.package;
        environmentFiles = [
          # same provider/skill env as hermes-agent.service, so webui chats
          # have CLI parity (fallback chain, duolingo, calendar)
          config.age.secrets.hermes-env.path
          config.age.secrets.duolingo-env.path
          config.age.secrets.radicale-hermes-env.path
          config.age.secrets.deepseek-env.path
        ];
        # anki seat parity with the agent service (see anki block above)
        extraEnvironment = lib.mkIf config.osbmModules.services.anki-sync-server.enable {
          ANKI_SYNC_ENDPOINT = "http://127.0.0.1:${toString config.services.anki-sync-server.port}/";
          ANKI_SYNC_USERNAME = "osbm";
          ANKI_SYNC_PASSWORD_FILE = config.age.secrets.anki-sync-password.path;
        };
      };

      systemd.services.hermes-webui = {
        # not required (webui reads the store lazily), but let the agent
        # create/migrate HERMES_HOME first on boot
        after = [ "hermes-agent.service" ];
        # tool exec from webui chats needs the same runtime as the agent unit
        path = [
          config.services.hermes-agent.package
          pkgs.bash
          pkgs.coreutils
          pkgs.git
          hermes-python
        ]
        ++ lib.optional config.osbmModules.services.anki-sync-server.enable anki-python;

        serviceConfig = {
          # group-share the den like every other hermes writer; the upstream
          # module's 0077 would make the janitor re-chmod everything it touches
          UMask = lib.mkForce "0007";

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [
            "/var/lib/hermes"
            "/var/lib/hermes-webui"
          ];
          ReadOnlyPaths = [ "-/var/lib/wanikani-logs" ];
          PrivateTmp = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          LockPersonality = true;
        };
      };

      services.nginx.virtualHosts."chat.osbm.dev" = {
        forceSSL = true;
        useACMEHost = "osbm.dev";
        locations."/" = {
          proxyPass = "http://127.0.0.1:8787";
          proxyWebsockets = true;
          extraConfig = ''
            allow 100.64.0.0/10;
            allow fd7a:115c:a1e0::/48;
            deny all;
            # the webui's CSRF gate compares the browser Origin against the
            # Host header it receives — without this it sees 127.0.0.1:8787
            # and rejects every POST ("Cross-origin mismatch")
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            # chat streams over SSE: unbuffered, and outlive the 60s default
            # read timeout between heartbeats
            proxy_buffering off;
            proxy_read_timeout 1h;
          '';
        };
      };
    })

    # impermanence: memories, skills, sessions and config live here
    (lib.mkIf (cfg.enable && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot) {
      environment.persistence."/persist" = {
        directories = [
          {
            directory = "/var/lib/hermes";
            user = "hermes";
            group = "hermes";
            mode = "0770";
          }
          # webui sessions/settings state (separate from the den by design)
          {
            directory = "/var/lib/hermes-webui";
            user = "hermes";
            group = "hermes";
            mode = "0700";
          }
        ];
      };
    })
  ];
}
