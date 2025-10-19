{ lib, config, ... }:
{
  config = lib.mkIf config.osbmModules.agenix.enable {
    # Agenix will be configured via the agenix input
    # This module exists to enable agenix-related configurations
    age.identityPaths = lib.mkDefault [
      "/etc/ssh/ssh_host_ed25519_key"
    ];
  };
}
