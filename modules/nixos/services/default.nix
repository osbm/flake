{
  imports = [
    ./anubis.nix
    ./atticd.nix
    ./caddy.nix
    ./cloudflare-dyndns.nix
    ./cloudflared.nix
    ./nextcloud.nix
    ./ollama.nix
    ./openssh.nix
    ./forgejo.nix
    ./glance.nix
    ./hydra.nix
    ./jellyfin.nix
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
