{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.cloudflared.enable {
      services.cloudflared = {
        enable = true;
        certificateFile = "/home/osbm/.cloudflared/cert.pem";
      };
    })
  ];
}
