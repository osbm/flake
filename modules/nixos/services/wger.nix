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
        image = "wger/server:latest";
        ports = [ "127.0.0.1:8283:80" ];
        volumes = [
          "/var/lib/wger/db:/home/wger/db"
          "/var/lib/wger/media:/home/wger/media"
          "/var/lib/wger/static:/home/wger/static"
        ];
        environmentFiles = [ "/var/lib/wger/env" ];
      };
    };

    # secret key generated once on first start; env file also carries the
    # site config so it survives image updates
    systemd.services.podman-wger.preStart = ''
      mkdir -p /var/lib/wger/db /var/lib/wger/media /var/lib/wger/static
      if [ ! -f /var/lib/wger/env ]; then
        {
          echo "SECRET_KEY=$(head -c 32 /dev/urandom | base64 | tr -d '=+/')"
          echo "SITE_URL=https://wger.osbm.dev"
          echo "CSRF_TRUSTED_ORIGINS=https://wger.osbm.dev"
          echo "X_FORWARDED_PROTO_HEADER_SET=True"
          # single-user home instance: no open registration
          echo "ALLOW_REGISTRATION=False"
          echo "ALLOW_GUEST_USERS=False"
        } > /var/lib/wger/env
        chmod 600 /var/lib/wger/env
      fi
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
