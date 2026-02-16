{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.tailscale.enable {
      services.tailscale = {
        enable = true;
        port = 51513;
      };

      networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
      environment.systemPackages = [ pkgs.tailscale ];
    })

    # tailscale and impermanence
    (lib.mkIf
      (
        config.osbmModules.services.tailscale.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        environment.persistence."/persist".directories = [
          "/var/lib/tailscale"
        ];
      }
    )
  ];
}
