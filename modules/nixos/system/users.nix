{ lib, config, ... }:
{
  config = {
    users.users = lib.mkMerge [
      # Default user
      {
        ${config.osbmModules.defaultUser} = {
          isNormalUser = true;
          description = config.osbmModules.defaultUser;
          initialPassword = "changeme";
          extraGroups = [
            "wheel"
            "networkmanager"
          ]
          ++ lib.optional config.osbmModules.virtualisation.docker.enable "docker";
          openssh.authorizedKeys.keys = lib.mkDefault [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k"
          ];
        };
      }

      # Family user (bayram)
      (lib.mkIf config.osbmModules.familyUser.enable {
        bayram = {
          isNormalUser = true;
          description = "bayram";
          initialPassword = "changeme";
          extraGroups = [
            "networkmanager"
          ]
          ++ lib.optional config.osbmModules.virtualisation.docker.enable "docker";
        };
      })

      # Root user
      {
        root = {
          initialPassword = "changeme";
          openssh.authorizedKeys.keys = lib.mkDefault [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k"
          ];
        };
      }
    ];
  };
}
