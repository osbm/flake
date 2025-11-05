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
        
        # Ensure ACME challenge directory is accessible for all domains
        commonHttpConfig = ''
          # Allow access to ACME challenge directory
          location /.well-known/acme-challenge {
            root /var/lib/acme/acme-challenge;
            allow all;
          }
        '';
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];

      security.acme = {
        acceptTerms = true;
        defaults.email = "osbm@osbm.dev";
      };
    })

    (lib.mkIf
      (
        config.osbmModules.services.nginx.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        environment.persistence."/persist" = {
          directories = [
            {
              directory = "/var/lib/acme";
              user = "acme";
              group = "nginx";
              mode = "0750";
            }
          ];
        };
      }
    )
  ];
}
