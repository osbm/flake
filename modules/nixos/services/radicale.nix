{
  config,
  lib,
  pkgs,
  ...
}:
let
  # first match wins. Owner rules mirror radicale's defaults; on top of them
  # the hermes agent gets its own calendar under osbm's principal (so osbm's
  # clients auto-discover it) and read access to the rest of osbm's data.
  rightsFile = pkgs.writeText "radicale-rights" ''
    [hermes-agenda-full]
    user: hermes
    collection: osbm/hermes-agenda
    permissions: RrWw

    [hermes-reads-osbm]
    user: hermes
    collection: osbm(/[^/]+)?
    permissions: Rr

    [root]
    user: .+
    collection:
    permissions: R

    [principal]
    user: .+
    collection: {user}
    permissions: RW

    [collections]
    user: .+
    collection: {user}/[^/]+
    permissions: rw
  '';
in
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.radicale.enable {
      services.radicale = {
        enable = true;
        settings = {
          server = {
            hosts = [ "127.0.0.1:5232" ];
          };
          auth = {
            type = "htpasswd";
            htpasswd_filename = "/var/lib/radicale/htpasswd";
            htpasswd_encryption = "bcrypt";
          };
          rights = {
            type = "from_file";
            file = toString rightsFile;
          };
          storage = {
            filesystem_folder = "/var/lib/radicale/collections";
          };
        };
      };
    })

    # radicale reverse proxy via nginx
    (lib.mkIf (config.osbmModules.services.nginx.enable && config.osbmModules.services.radicale.enable)
      {
        services.nginx.virtualHosts."cal.osbm.dev" = {
          forceSSL = true;
          useACMEHost = "osbm.dev";
          locations."/" = {
            proxyPass = "http://localhost:5232";
            extraConfig = ''
              proxy_set_header X-Script-Name /;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header Host $host;
            '';
          };
        };
      }
    )

    # impermanence with radicale
    (lib.mkIf
      (
        config.osbmModules.services.radicale.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        environment.persistence."/persist" = {
          directories = [
            {
              directory = "/var/lib/radicale";
              user = "radicale";
              group = "radicale";
              mode = "0750";
            }
          ];
        };
      }
    )
  ];
}
