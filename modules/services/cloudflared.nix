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
        tunnels = {
          "eb9052aa-9867-482f-80e3-97a7d7e2ef04" = {
            default = "http_status:404";
            credentialsFile = "/home/osbm/.cloudflared/eb9052aa-9867-482f-80e3-97a7d7e2ef04.json";
            ingress = {
              "git.osbm.dev" = {
                service = "http://localhost:3000";
              };
            };
          };
          "288d47fb-95ee-4019-9e07-6f918ab02357" = {
            default = "http_status:404";
            credentialsFile = "/home/osbm/.cloudflared/288d47fb-95ee-4019-9e07-6f918ab02357.json";
            ingress = {
              "git.osbm.dev" = {
                service = "http://localhost:3000";
              };
            };
          };
        };
      };
    })
  ];
}
