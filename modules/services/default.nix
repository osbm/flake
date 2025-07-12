{
  imports = [
    ./caddy.nix
    ./cloudflare-dyndns.nix
    ./cloudflared.nix
    ./nextcloud.nix
    ./ollama.nix
    ./forgejo.nix
    ./jellyfin.nix
    ./system-logger/
    ./tailscale.nix
    ./vaultwarden.nix
    ./vscode-server.nix
    ./wanikani-bypass-lessons.nix
    ./wanikani-fetch-data
  ];
}
