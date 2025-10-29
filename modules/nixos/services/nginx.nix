{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.nginx.enable {
      services.nginx = {
        enable = true;
      };

      networking.firewall.allowedTCPPorts = [ 80 443 ];

      security.acme = {
        acceptTerms = true;
        defaults.email = "osbm@osbm.dev";
      };
    })
  ];
}
