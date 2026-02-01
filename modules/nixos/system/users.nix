{ lib, config, ... }:
{
  config = {
    users.users = lib.mkMerge [
      # Default user
      {
        ${config.osbmModules.defaultUser} = {
          isNormalUser = true;
          description = config.osbmModules.defaultUser;
          initialHashedPassword = "$6$Zl1oNw5D8zux3UbQ$v5RuZNRrNtBIVm9W6eNUNE3AhI0ardv.3iDMDnFTjoeTejM6wJzUrKgoKsp2uCgPOBqMkIn7OjiHhU7V2zC5z.";
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
