{ lib, config, ... }:
let
  cfg = config.osbmModules;
in
{
  config = lib.mkIf (cfg.users != []) {
    users.users = lib.mkMerge [
      # Create users based on the list
      (lib.genAttrs cfg.users (username: {
        isNormalUser = true;
        description = username;
        extraGroups = [ "networkmanager" ]
          ++ lib.optional (username == cfg.defaultUser) "wheel"
          ++ lib.optional config.osbmModules.virtualization.docker.enable "docker"
          ++ lib.optional config.osbmModules.programs.adbFastboot.enable "adbusers";
      }))

      # Additional configuration for default user
      {
        ${cfg.defaultUser} = {
          openssh.authorizedKeys.keys = lib.mkDefault [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k"
          ];
        };
      }
    ];

  };
}
