{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  config = lib.mkIf config.osbmModules.agenix.enable {
    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.agenix
      pkgs.age
    ];

    age.secrets = {
      vaultwarden.file = ../../../secrets/vaultwarden.age;
      network-manager.file = ../../../secrets/network-manager.age;
      osbm-mail.file = ../../../secrets/osbm-mail.age;
      forgejo-mail.file = ../../../secrets/forgejo-mail.age;
      vaultwarden-mail.file = ../../../secrets/vaultwarden-mail.age;
      noreply-mail.file = ../../../secrets/noreply-mail.age;
      cloudflare-apollo-zone-dns-edit.file = ../../../secrets/cloudflare-apollo-zone-dns-edit.age;
      ssh-key-private = {
        file = ../../../secrets/ssh-key-private.age;
        path = "/home/osbm/.ssh/id_ed25519";
        owner = "osbm";
        group = "users";
        mode = "600";
      };
      ssh-key-public = {
        file = ../../../secrets/ssh-key-public.age;
        path = "/home/osbm/.ssh/id_ed25519.pub";
        owner = "osbm";
        group = "users";
        mode = "644";
      };

      # Deploy same SSH key to root for backups
      root-ssh-key-private = {
        file = ../../../secrets/ssh-key-private.age;
        path = "/root/.ssh/id_ed25519";
        owner = "root";
        group = "root";
        mode = "600";
      };
      root-ssh-key-public = {
        file = ../../../secrets/ssh-key-public.age;
        path = "/root/.ssh/id_ed25519.pub";
        owner = "root";
        group = "root";
        mode = "644";
      };
    };

  };
}
