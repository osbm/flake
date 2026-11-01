{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.osbmModules.services.ollama;
  # open-webui listens here on the host network; apollo's nginx proxies
  # openwebui.osbm.dev -> ymir.curl-boga.ts.net:7070 (see nginx.nix)
  openWebuiPort = 7070;
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        # loadModels = [
        #   "deepseek-r1:7b"
        #   "deepseek-r1:14b"
        # ];
      };

      # Open WebUI: the nixpkgs package is unbuildable as of 2026-11-02
      # (its posthog dep is marked broken against mcp >= 2, and it is unfree
      # on top), so the official container runs under podman like wger does.
      # host networking so it reaches ollama on loopback without exposing
      # ollama itself beyond 127.0.0.1.
      virtualisation.podman.enable = true;
      virtualisation.oci-containers = {
        backend = "podman";
        containers.open-webui = {
          # v0.12.5, digest-pinned (2026-11-02); update = bump digest, rebuild
          image = "ghcr.io/open-webui/open-webui@sha256:03443b8de6b617da9d900edd09b4bf1cb0ddbfdcba6afb42c548336a0b821ded";
          volumes = [ "/var/lib/open-webui:/app/backend/data" ];
          environment = {
            HOST = "0.0.0.0";
            PORT = toString openWebuiPort;
            OLLAMA_BASE_URL = "http://127.0.0.1:${toString config.services.ollama.port}";
            WEBUI_URL = "https://openwebui.osbm.dev";
            # single user, tailnet-only (the nginx vhost rejects everything
            # else) — no login screen
            WEBUI_AUTH = "False";
            SCARF_NO_ANALYTICS = "True";
            DO_NOT_TRACK = "True";
            ANONYMIZED_TELEMETRY = "False";
          };
          extraOptions = [ "--network=host" ];
        };
      };

      systemd.tmpfiles.rules = [ "d /var/lib/open-webui 0750 root root -" ];

      # no point coming up before the model server; also avoids the
      # "ollama unreachable" banner on first load after boot
      systemd.services.podman-open-webui = {
        after = [ "ollama.service" ];
        wants = [ "ollama.service" ];
      };

      # reachable from the tailnet only (apollo's nginx is the client);
      # nothing on LAN or the public interface
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ openWebuiPort ];
    })
  ];
}
