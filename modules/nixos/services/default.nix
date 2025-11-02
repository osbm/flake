{
  imports = [
    ./anubis.nix
    ./atticd.nix
    ./cloudflare-dyndns.nix
    ./cloudflared.nix
    ./ollama.nix
    ./openssh.nix
    ./firefox-syncserver.nix
    ./forgejo.nix
    ./glance.nix
    ./hydra.nix
    ./immich.nix
    ./jellyfin.nix
    ./mailserver.nix
    ./nginx.nix
    ./seafile.nix
    ./syncthing.nix
    ./tailscale.nix
    ./vaultwarden.nix
    ./vscode-server.nix

    # custom services
    ./system-logger
    ./wanikani-bypass-lessons.nix
    ./wanikani-fetch-data
    ./wanikani-stats
  ];
}
