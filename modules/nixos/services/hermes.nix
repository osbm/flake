{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.osbmModules.services.hermes;
in
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.hermes-agent = {
        enable = true;
        # hermes CLI/TUI/dashboard for interactive use, shares the service HERMES_HOME
        addToSystemPackages = true;
        environmentFiles = [ config.age.secrets.hermes-env.path ];
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

      # let the main user run `hermes` against the service state
      users.users.${config.osbmModules.defaultUser}.extraGroups = [ "hermes" ];

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
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
          "AF_NETLINK"
        ];
      };
    })

    # web dashboard behind nginx, reachable only over tailscale:
    # hermes.osbm.dev resolves to apollo's tailnet IP, and the vhost
    # additionally rejects non-tailnet sources in case the public IP is hit
    # directly with a matching SNI.
    (lib.mkIf (cfg.enable && config.osbmModules.services.nginx.enable) {
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
          ExecStart = "${config.services.hermes-agent.package}/bin/hermes serve --skip-build --host 127.0.0.1 --port 9119";
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
