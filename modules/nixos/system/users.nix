{ lib, config, ... }:
let
  cfg = config.osbmModules;
  # Filter out 'root' from the users list since it's a special system user
  regularUsers = builtins.filter (u: u != "root") cfg.users;
in
{
  config = lib.mkIf (cfg.users != []) {
    users.users = lib.mkMerge [
      # Create users based on the list (excluding root)
      (lib.genAttrs regularUsers (username: {
        isNormalUser = true;
        description = username;
        extraGroups = [ "networkmanager" ]
          ++ lib.optional (username == cfg.defaultUser) "wheel"
          ++ lib.optional config.osbmModules.virtualization.docker.enable "docker"
          ++ lib.optional config.osbmModules.programs.adbFastboot.enable "adbusers";
      }))

      # Additional configuration for default user (including root if it's default)
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
