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

        # Set all no-reply addresses
        rejectRecipients = [ "noreply@osbm.dev" ];

        # A list of all login accounts. To create the password hashes, use
        # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
        loginAccounts = {
          "osbm@osbm.dev" = {
            hashedPasswordFile = config.age.secrets."osbm-mail".path;
            aliases = [
              "osbm"
              "osman@osbm.dev"
              "postmaster@osbm.dev"
              "root@osbm.dev"
              "mastercontrol@osbm.dev"
              "admin@osbm.dev"
            ];
          };
          "forgejo@osbm.dev" = {
            hashedPasswordFile = config.age.secrets."forgejo-mail".path;
          };
          "vaultwarden@osbm.dev" = {
            hashedPasswordFile = config.age.secrets."vaultwarden-mail".path;
          };
          "noreply@osbm.dev" = {
            hashedPasswordFile = config.age.secrets."noreply-mail".path;
          };
        };
        # reference an existing ACME configuration
        x509.useACMEHost = config.mailserver.fqdn;

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
