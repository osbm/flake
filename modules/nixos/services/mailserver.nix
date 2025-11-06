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
            # Dovecot is an open source IMAP and POP3 server
            # which means it handles email retrieval for users.
            "/var/lib/dovecot" # owned by root
            # Postfix is a open-source mail transfer agent (MTA)
            "/var/lib/postfix" # owned by root
            # Rspamd is a open-source spam filtering system.
            {
              directory = "/var/lib/rspamd";
              user = "rspamd";
              group = "rspamd";
              mode = "0700";
            }
            # redis-rspamd is just a redis instance used by rspamd for caching
            # TODO: what is the /var/spool folder?
            {
              directory = "/var/spool/redis-rspamd";
              user = "redis-rspamd";
              group = "redis-rspamd";
              mode = "0750";
            }
            # Sieve is a scripting language for filtering email messages.
            {
              directory = config.mailserver.sieveDirectory; # /var/sieve by default
              user = "virtualMail";
              group = "virtualMail";
              mode = "0770";
            }
            # Mail folder
            {
              directory = config.mailserver.mailDirectory; # /var/vmail by default
              user = config.mailserver.vmailUserName;
              group = config.mailserver.vmailGroupName;
              mode = "0700";
            }
            # DKIM is used to sign outgoing emails to verify they are from the claimed domain.
            {
              directory = config.mailserver.dkimKeyDirectory; # /var/dkim by default
              user = "rspamd";
              group = "rspamd";
              mode = "0755";
            }
          ];
        };
      }
    )
  ];
}
