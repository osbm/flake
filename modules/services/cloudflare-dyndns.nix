{
  lib,
  config,
  ...
}: {
  options = {
    myModules.enableCloudflareDyndns = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable a service to push my public IP address to my Cloudflare domain.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableCloudflareDyndns {
      services.cloudflare-dyndns = {
        enable = true;
      };
    })
  ];
}
