{
  pkgs,
  lib,
  config,
  ...
}:
{
  options = {
    myModules.enableWakeOnLan = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Wake on LAN";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableWakeOnLan {
      networking.interfaces.enp3s0.wakeOnLan.enable = true;
      # The services doesn't actually work atm, define an additional service
      # see https://github.com/NixOS/nixpkgs/issues/91352
      systemd.services.wakeonlan = {
        description = "Reenable wake on lan every boot";
        after = [ "network.target" ];
        serviceConfig = {
          Type = "simple";
          RemainAfterExit = "true";
          ExecStart = "${pkgs.ethtool}/sbin/ethtool -s enp3s0 wol g";
        };
        wantedBy = [ "default.target" ];
      };
    })
  ];
}
