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
        # environment.persistence."/persist" = {
        #   directories = [
        #     {
        #       directory = "/var/lib/acme";
        #       user = "acme";
        #       group = "nginx";
        #       mode = "0750";
        #     }
        #   ];
        # };
      }
    )
  ];
}
