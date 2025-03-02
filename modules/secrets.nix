{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  options = {
    myModules.enableSecrets = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable agenix secrets management";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableSecrets {
      environment.systemPackages = [
        inputs.agenix.packages.${pkgs.hostPlatform.system}.agenix
        pkgs.age
      ];

      age.secrets = {
        network-manager.file = ../secrets/network-manager.age;
        ssh-key-private = {
          file = ../secrets/ssh-key-private.age;
          path = "/home/osbm/.ssh/id_ed25519";
          owner = "osbm";
          mode = "0600";
        };
        ssh-key-public = {
          file = ../secrets/ssh-key-public.age;
          path = "/home/osbm/.ssh/id_ed25519.pub";
          owner = "osbm";
          mode = "0644";
        };
        cloudflare.file = ../secrets/cloudflare.age;
      };
    })
  ];
}
