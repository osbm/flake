{
  config,
  lib,
  ...
}:
{
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
        tunnels."eb9052aa-9867-482f-80e3-97a7d7e2ef04" = {
          default = "http_status:404";
          credentialsFile = "/home/osbm/.cloudflared/eb9052aa-9867-482f-80e3-97a7d7e2ef04.json";
          ingress = {
            "git.osbm.dev" = {
              service = "http://localhost:3000";
            };
          };
        };
      };
      boot.kernel.sysctl = {
        "net.core.rmem_max" = 7500000;
        "net.core.wmem_max" = 7500000;
      };
    })
  ];
}
