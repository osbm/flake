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
        tunnels."ffe51e83-5516-44e5-9c8b-2b140cdfece9" = {
          default = "http_status:404";
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
