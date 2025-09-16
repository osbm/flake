{
  config,
  lib,
  ...
}:
{
  options = {
    myModules.enableOpenssh = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable OpenSSH service";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableOpenssh {
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
