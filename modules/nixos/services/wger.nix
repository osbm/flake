{
  config,
  lib,
  ...
}:
let
  cfg = config.osbmModules.services.wger;
in
{
  config = lib.mkIf cfg.enable {
    # wger: self-hosted workout/nutrition/body-weight tracker (Hevy without
    # the subscription). No nixpkgs package, so the official container runs
    # standalone — single-user instance, sqlite is plenty. Phone app and
    # browser talk to wger.osbm.dev over the tailnet.
    virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.wger = {
        # fully qualified — podman has no unqualified-search registries on NixOS
        image = "docker.io/wger/server:latest";
        # gunicorn listens on 8000 inside the container (not 80)
        ports = [ "127.0.0.1:8283:8000" ];
        volumes = [
          "/var/lib/wger/db:/home/wger/db"
          "/var/lib/wger/media:/home/wger/media"
          "/var/lib/wger/static:/home/wger/static"
        ];
        environmentFiles = [ "/var/lib/wger/env" ];
      };
    };

    # the env file is regenerated declaratively on every start; only the
    # secrets (django SECRET_KEY + JWT keypair for the mobile app) persist in
    # /var/lib/wger/secrets.env. JWT keys can't be generated here — they come
    # from `podman exec wger ./manage.py generate-jwt-keys` once; the app
    # works without them until then (web login is session-based).
    systemd.services.podman-wger.preStart = ''
      mkdir -p /var/lib/wger/db /var/lib/wger/media /var/lib/wger/static
      # container runs as uid 1000; volumes must be writable by it
      chown -R 1000:1000 /var/lib/wger/db /var/lib/wger/media /var/lib/wger/static
      if [ ! -f /var/lib/wger/secrets.env ]; then
        echo "SECRET_KEY=$(head -c 32 /dev/urandom | base64 | tr -d '=+/')" \
          > /var/lib/wger/secrets.env
        chmod 600 /var/lib/wger/secrets.env
      fi
      {
        cat /var/lib/wger/secrets.env
        cat <<'CFG'
      SITE_URL=https://wger.osbm.dev
      CSRF_TRUSTED_ORIGINS=https://wger.osbm.dev
      X_FORWARDED_PROTO_HEADER_SET=True
      NUMBER_OF_PROXIES=1
      # single-user home instance: no open registration
      ALLOW_REGISTRATION=False
      ALLOW_GUEST_USERS=False
      TIME_ZONE=Europe/Istanbul
      TZ=Europe/Istanbul
      # latest image has no DB defaults — sqlite is plenty for one user
      DJANGO_DB_ENGINE=django.db.backends.sqlite3
      DJANGO_DB_DATABASE=/home/wger/db/database.sqlite
      DJANGO_DB_USER=
      DJANGO_DB_PASSWORD=
      DJANGO_DB_HOST=
      DJANGO_DB_PORT=5432
      PS_DATABASE_URI=
      # no redis: in-process cache, celery off (sync jobs run via manage.py)
      DJANGO_CACHE_BACKEND=django.core.cache.backends.locmem.LocMemCache
      DJANGO_CACHE_LOCATION=
      USE_CELERY=False
      SYNC_EXERCISES_CELERY=False
      SYNC_EXERCISE_IMAGES_CELERY=False
      SYNC_EXERCISE_VIDEOS_CELERY=False
      SYNC_INGREDIENTS_CELERY=False
      CACHE_API_EXERCISES_CELERY=False
      DJANGO_PERFORM_MIGRATIONS=True
      DJANGO_COLLECTSTATIC_ON_STARTUP=True
      WGER_USE_GUNICORN=True
      DJANGO_DEBUG=False
      CFG
      } > /var/lib/wger/env
      chmod 600 /var/lib/wger/env
    '';

    # tailnet-only, same pattern as hledger/aw
    services.nginx.virtualHosts."wger.osbm.dev" = lib.mkIf config.osbmModules.services.nginx.enable {
      forceSSL = true;
      useACMEHost = "osbm.dev";
      locations."/" = {
        proxyPass = "http://127.0.0.1:8283";
        extraConfig = ''
          allow 100.64.0.0/10;
          allow fd7a:115c:a1e0::/48;
          deny all;
          client_max_body_size 100M;
        '';
      };
    };

    # workout history + nutrition log are the books of the body — persist
    environment.persistence."/persist" =
      lib.mkIf config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
        {
          directories = [ "/var/lib/wger" ];
        };
  };
}
