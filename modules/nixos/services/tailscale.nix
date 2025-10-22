{
  config,
  lib,
  pkgs,
  ...
}:
{

  # i have 4 machines, 2 of them are always at home
  # pochita (raspberry pi 5) and ymir (desktop)
  # pochita will be on all the time, ymir can be wake on lan

  # and i have a laptop named tartarus

  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.tailscale.enable {
      services.tailscale = {
        enable = true;
        port = 51513;
      };

      networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
      environment.systemPackages = [ pkgs.tailscale ];
    })
  ];
}
