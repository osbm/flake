{
  config,
  lib,
  ...
}: {
  options = {
    myModules.enableCloudflared = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Cloudflare tunnels";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableCloudflared {
      services.cloudflared = {
        enable = true;
        certificateFile = "/home/osbm/.cloudflared/cert.pem";
        tunnels."forgejo-service" = {
          default = "http_status:404";
          credentialsFile = "/persist/cloudflare-forgejo.json";
          ingress = {
            "git.osbm.dev" = {
              service = "http://localhost:3000";
            };
          };
        };
      };
    })
  ];
}
