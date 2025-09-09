{ lib, config, ... }:
{
  options = {
    myModules.setUsers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable user management.";
    };
  };

  config = lib.mkIf config.myModules.setUsers {
    users.users = {
      osbm = {
        isNormalUser = true;
        description = "osbm";
        initialHashedPassword = "$6$IamAbigfailure$irfkAsWev8CMAr78wUwUggclplXL98sbI21fpGY9nMDz47bU88RZWFLO7FcN5SdRA18ZSidkMqS76uLCMH68f.";
        extraGroups = [
          "networkmanager"
          "wheel"
          "docker"
        ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k"
        ];
        packages = [
        ];
      };
      bayram = {
        isNormalUser = true;
        description = "bayram";
        initialHashedPassword = "$6$IamAbigfailure$3BP231DVwbqUtZ.mq33nM/JitBrT2u26Y25VpsfBwhZbezMHz4XbySrOMnaMcCYdsb3wZFL3Ppcp0L.R8nonT.";
        extraGroups = [ "networkmanager" ];
        packages = [
        ];
      };
      root.initialHashedPassword = "$6$IamAbigfailure$irfkAsWev8CMAr78wUwUggclplXL98sbI21fpGY9nMDz47bU88RZWFLO7FcN5SdRA18ZSidkMqS76uLCMH68f.";
    };
  };
}
