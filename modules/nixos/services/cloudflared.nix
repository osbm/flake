{
  config,
  lib,
  ...
}:
{
  options = {
    osbmModules.enableCloudflared = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Cloudflare tunnels";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.enableCloudflared {
      services.cloudflared = {
        enable = true;
        certificateFile = "/home/osbm/.cloudflared/cert.pem";
      };
    })
  ];
}
