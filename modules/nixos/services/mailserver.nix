{
  config,
  inputs,
  lib,
  ...
}:
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
            aliases = [ "postmaster@osbm.dev" ];
          };
        };

        # Use Let's Encrypt certificates. Note that this needs to set up a stripped
        # down nginx and opens port 80.
        certificateScheme = "acme-nginx";
      };
    })

    # mailserver and impermanence
    (lib.mkIf
      (
        config.osbmModules.services.mailserver.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        environment.persistence."/persist" = {
          directories = [
            # TODO write justifications for each of these
            "/var/lib/dovecot" # owned by root
            "/var/lib/postfix" # owned by root
            {
              directory = "/var/lib/rspamd";
              user = "rspamd";
              group = "rspamd";
              mode = "0750";
            }
            {
              directory = "/var/spool/redis-rspamd";
              user = "redis-rspamd";
              group = "redis-rspamd";
              mode = "0750";
            }
            {
              directory = "/var/sieve";
              user = "virtualMail";
              group = "virtualMail";
              mode = "0770";
            }
            {
              directory = "/var/vmail";
              user = "virtualMail";
              group = "virtualMail";
              mode = "0700";
            }
            {
              directory = "/var/dkim";
              user = "rspamd";
              group = "rspamd";
              mode = "0755";
            }
            "/var/spool"
          ];
        };
      })
  ];
}
