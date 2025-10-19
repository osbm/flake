{ lib, config, ... }:
let
  cfg = config.osbmModules.virtualization;
in
{
  config = lib.mkMerge [
    # Docker
    (lib.mkIf cfg.docker.enable {
      virtualisation.docker.enable = true;
      virtualisation.docker.storageDriver = lib.mkDefault "overlay2";
    })

    # Podman
    (lib.mkIf cfg.podman.enable {
      virtualisation.podman = {
        enable = true;
        dockerCompat = lib.mkDefault true;
        defaultNetwork.settings.dns_enabled = true;
      };
    })

    # Libvirt/KVM
    (lib.mkIf cfg.libvirt.enable {
      virtualisation.libvirtd.enable = true;
      programs.virt-manager.enable = true;
    })
  ];
}
