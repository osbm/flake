{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.openssh.enable {
      services.openssh = {
        enable = true;
        startWhenNeeded = true;
        settings = {
          PermitRootLogin = "no";

          # only allow key based logins and not password
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          AuthenticationMethods = "publickey";
          PubkeyAuthentication = "yes";
          ChallengeResponseAuthentication = "no";
          UsePAM = false;

          # kick out inactive sessions
          ClientAliveCountMax = 5;
          ClientAliveInterval = 60;
        };
      };

    })
  ];
}
