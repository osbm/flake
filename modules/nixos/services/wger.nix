{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.osbmModules.services.wger;
  # vendored from wger-project/docker (services/config-powersync + initdb)
  powersyncConfig = ./wger-powersync;
in
{
  config = lib.mkIf cfg.enable {
    # wger: self-hosted workout/nutrition/body-weight tracker (Hevy without
    # the subscription). No nixpkgs package, so the official containers run
    # under podman. The mobile app additionally requires PowerSync (offline
    # sync), which needs postgres with logical replication — hence the full
    # three-container stack on a shared network, mirroring upstream compose:
    #   wger-db (postgres) <- wger (django/gunicorn) <- wger-powersync
    virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        wger-db = {
          image = "docker.io/postgres:15-alpine";
          volumes = [
            "/var/lib/wger/postgres:/var/lib/postgresql/data"
            # creates the powersync_storage user+schema on first init only
            "/var/lib/wger/initdb:/docker-entrypoint-initdb.d:ro"
          ];
          environmentFiles = [ "/var/lib/wger/db.env" ];
          # powersync replicates via logical WAL
          cmd = [
            "postgres"
            "-c"
            "wal_level=logical"
            "-c"
            "max_connections=30"
            "-c"
            "shared_buffers=256MB"
          ];
          extraOptions = [ "--network=wger-net" ];
        };

        wger = {
          image = "docker.io/wger/server:latest";
          # gunicorn listens on 8000 inside the container
          ports = [ "127.0.0.1:8283:8000" ];
          volumes = [
            "/var/lib/wger/media:/home/wger/media"
            "/var/lib/wger/static:/home/wger/static"
          ];
          environmentFiles = [ "/var/lib/wger/wger.env" ];
          extraOptions = [ "--network=wger-net" ];
        };

        wger-powersync = {
          image = "docker.io/journeyapps/powersync-service:latest";
          cmd = [
            "start"
            "-r"
            "unified"
          ];
          ports = [ "127.0.0.1:8284:8080" ];
          volumes = [ "/var/lib/wger/config-powersync:/config:ro" ];
          environmentFiles = [ "/var/lib/wger/powersync.env" ];
          extraOptions = [ "--network=wger-net" ];
        };
      };
    };

    # one init service prepares everything the three containers share:
    # network, dirs, generated secrets, env files, vendored configs.
    # Secrets persist in /var/lib/wger/secrets.env (SECRET_KEY, PG_PASSWORD,
    # and the JWT keypair for the mobile app — generated once via
    # `podman exec wger ./manage.py generate-jwt-keys`, web login works
    # without it).
    systemd.services.wger-init = {
      description = "wger stack init (network, secrets, env files)";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      path = [
        pkgs.podman
        pkgs.gnugrep
      ];
      script = ''
        podman network exists wger-net || podman network create wger-net

        mkdir -p /var/lib/wger/postgres /var/lib/wger/media /var/lib/wger/static \
                 /var/lib/wger/initdb /var/lib/wger/config-powersync
        # wger container runs as uid 1000
        chown -R 1000:1000 /var/lib/wger/media /var/lib/wger/static

        install -m 644 ${powersyncConfig}/powersync.yaml /var/lib/wger/config-powersync/powersync.yaml
        install -m 644 ${powersyncConfig}/sync_rules.yaml /var/lib/wger/config-powersync/sync_rules.yaml
        install -m 644 ${powersyncConfig}/powersync-init.sql /var/lib/wger/initdb/03-powersync.sql

        touch /var/lib/wger/secrets.env
        chmod 600 /var/lib/wger/secrets.env
        if ! grep -q "^SECRET_KEY=" /var/lib/wger/secrets.env; then
          echo "SECRET_KEY=$(head -c 32 /dev/urandom | base64 | tr -d '=+/')" >> /var/lib/wger/secrets.env
        fi
        if ! grep -q "^PG_PASSWORD=" /var/lib/wger/secrets.env; then
          echo "PG_PASSWORD=$(head -c 24 /dev/urandom | base64 | tr -d '=+/')" >> /var/lib/wger/secrets.env
        fi
        PG_PASSWORD=$(grep "^PG_PASSWORD=" /var/lib/wger/secrets.env | cut -d= -f2-)

        {
          echo "POSTGRES_USER=wger"
          echo "POSTGRES_PASSWORD=$PG_PASSWORD"
          echo "POSTGRES_DB=wger"
          echo "TZ=Europe/Istanbul"
        } > /var/lib/wger/db.env

        {
          # generated secrets + JWT keys if present
          grep -v "^PG_PASSWORD=" /var/lib/wger/secrets.env
          echo "DJANGO_DB_PASSWORD=$PG_PASSWORD"
          echo "PS_DATABASE_URI=postgres://wger:$PG_PASSWORD@wger-db:5432/wger"
          cat <<'CFG'
        SITE_URL=https://wger.osbm.dev
        CSRF_TRUSTED_ORIGINS=https://wger.osbm.dev
        X_FORWARDED_PROTO_HEADER_SET=True
        NUMBER_OF_PROXIES=1
        ALLOW_REGISTRATION=False
        ALLOW_GUEST_USERS=False
        TIME_ZONE=Europe/Istanbul
        TZ=Europe/Istanbul
        DJANGO_DB_ENGINE=django.db.backends.postgresql
        DJANGO_DB_DATABASE=wger
        DJANGO_DB_USER=wger
        DJANGO_DB_HOST=wger-db
        DJANGO_DB_PORT=5432
        # no redis: in-process cache, celery off (sync jobs via manage.py)
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
        # mobile app offline sync, served at SITE_URL/ps by nginx
        POWERSYNC_URL_PATH=ps
        PS_PORT=8080
        CFG
        } > /var/lib/wger/wger.env
        chmod 600 /var/lib/wger/wger.env

        {
          echo "POWERSYNC_CONFIG_PATH=/config/powersync.yaml"
          echo "PS_JWKS_URL=http://wger:8000/api/v2/powersync-keys"
          echo "PS_DATABASE_URI=postgres://wger:$PG_PASSWORD@wger-db:5432/wger"
          echo "PS_STORAGE_PG_URI=postgres://powersync_storage:powersync_password@wger-db:5432/wger"
          echo "PS_PORT=8080"
        } > /var/lib/wger/powersync.env
        chmod 600 /var/lib/wger/powersync.env
      '';
    };

    systemd.services.podman-wger-db = {
      after = [ "wger-init.service" ];
      requires = [ "wger-init.service" ];
    };
    systemd.services.podman-wger = {
      after = [
        "wger-init.service"
        "podman-wger-db.service"
      ];
      requires = [ "wger-init.service" ];
    };
    systemd.services.podman-wger-powersync = {
      after = [
        "wger-init.service"
        "podman-wger.service"
      ];
      requires = [ "wger-init.service" ];
    };

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
          # wger validates these to know it's behind an https proxy
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Real-IP $remote_addr;
        '';
      };
      # powersync API (websocket/stream) for the mobile app
      locations."/ps/" = {
        proxyPass = "http://127.0.0.1:8284/";
        extraConfig = ''
          allow 100.64.0.0/10;
          allow fd7a:115c:a1e0::/48;
          deny all;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_read_timeout 300s;
        '';
      };
      # gunicorn doesn't serve assets — nginx reads them straight from the
      # container volumes, as in wger's official compose setup
      locations."/static/" = {
        alias = "/var/lib/wger/static/";
        extraConfig = ''
          allow 100.64.0.0/10;
          allow fd7a:115c:a1e0::/48;
          deny all;
          expires 1d;
        '';
      };
      locations."/media/" = {
        alias = "/var/lib/wger/media/";
        extraConfig = ''
          allow 100.64.0.0/10;
          allow fd7a:115c:a1e0::/48;
          deny all;
          expires 1d;
        '';
      };
    };

    # workout history + nutrition log are the books of the body — persist
    environment.persistence."/persist" =
      lib.mkIf config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
        {
          directories = [
            "/var/lib/wger"
            # podman image + network storage — without this every reboot
            # re-pulls ~1GB of images before the stack can start
            "/var/lib/containers"
          ];
        };
  };
}
