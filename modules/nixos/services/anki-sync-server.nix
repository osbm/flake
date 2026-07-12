{
  config,
  lib,
  ...
}:
let
  cfg = config.osbmModules.services.anki-sync-server;
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      age.secrets.anki-sync-password.file = ../../../secrets/anki-sync-password.age;

      services.anki-sync-server = {
        enable = true;
        address = "127.0.0.1";
        # default port 27701, reachable only through nginx
        users = [
          {
            username = "osbm";
            passwordFile = config.age.secrets.anki-sync-password.path;
          }
        ];
      };
    })

    # tailnet-only subdomain, same pattern as hermes/wanikani-stats
    (lib.mkIf (cfg.enable && config.osbmModules.services.nginx.enable) {
      services.nginx.virtualHosts."anki.osbm.dev" = {
        forceSSL = true;
        useACMEHost = "osbm.dev";
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.anki-sync-server.port}";
          extraConfig = ''
            allow 100.64.0.0/10;
            allow fd7a:115c:a1e0::/48;
            deny all;
            # full collection uploads and media chunks
            client_max_body_size 512m;
          '';
        };
      };
    })

    # collections and media live here. The upstream unit uses DynamicUser,
    # which makes /var/lib/anki-sync-server a symlink into /var/lib/private —
    # persist the real directory, not the symlink target's parent.
    (lib.mkIf (cfg.enable && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot) {
      environment.persistence."/persist" = {
        directories = [
          {
            directory = "/var/lib/private/anki-sync-server";
            mode = "0700";
          }
        ];
      };
    })
  ];
}
