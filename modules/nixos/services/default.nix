{
  imports = [
    ./actual.nix
    ./anubis.nix
    ./atticd.nix
    ./backup-client.nix
    ./backup-server.nix
    ./ollama.nix
    ./openssh.nix
    ./forgejo.nix
    ./glance.nix
    ./hermes.nix
    ./hydra.nix
    ./immich.nix
    ./jellyfin.nix
    ./mailserver.nix
    ./nginx.nix
    ./paperless.nix
    ./ntfy.nix
    ./node-exporter.nix
    ./prometheus.nix
    ./loki.nix
    ./grafana
    ./alloy.nix
    ./healthcheck.nix
    ./radicale.nix
    ./syncthing.nix
    ./tailscale.nix
    ./vaultwarden.nix
    ./vscode-server.nix

    # custom services
    ./system-logger
    ./wanikani-fetch-data
    ./wanikani-stats

  ];
}
