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
  imports = [ inputs.hermes-agent.nixosModules.default ];

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
        ];
        # Claude Max subscription via `hermes login anthropic` (auth.json);
        # nix-managed keys win over TUI edits on every activation
        settings = {
          model = "anthropic/claude-opus-4.8";
          # fallback chain, tried in order when the subscription pool is
          # throttled/exhausted
          # haiku shares the subscription pool but has its own rate-limit
          # bucket, so it keeps telegram alive when sonnet/opus are throttled
          fallback_model = [
            {
              provider = "anthropic";
              model = "claude-haiku-4-5";
            }
            # {
            #   provider = "deepseek";
            #   model = "deepseek-v4-pro";
            # }
            # {
            #   provider = "gemini";
            #   model = "gemini-3.1-pro-preview";
            # }
          ];
        };
      };

      age.secrets.hermes-env.file = ../../../secrets/hermes-env.age;
      age.secrets.duolingo-env.file = ../../../secrets/duolingo-env.age;
      age.secrets.radicale-hermes-env.file = ../../../secrets/radicale-hermes-env.age;

      # let the main user run `hermes` against the service state
      users.users.${config.osbmModules.defaultUser}.extraGroups = [ "hermes" ];

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
        ];
      };
    })
  ];
}
