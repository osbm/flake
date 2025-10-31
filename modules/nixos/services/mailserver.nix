{ config, inputs, lib, ... }:
{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
  ];

  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.mailserver.enable {
      mailserver = {
        enable = true;
        stateVersion = 3;
        fqdn = "mail.osbm.dev";
        domains = [ "osbm.dev" ];

        # A list of all login accounts. To create the password hashes, use
        # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
        loginAccounts = {
          "osbm@osbm.dev" = {
            hashedPasswordFile = "/persist/osbm.passwd"; # TODO: Make this into agenix secret
            aliases = ["postmaster@osbm.dev"];
          };
        };

        # Use Let's Encrypt certificates. Note that this needs to set up a stripped
        # down nginx and opens port 80.
        certificateScheme = "acme-nginx";
      };
    })
  ];
}