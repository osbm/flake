{ lib, config, ... }:
{
  config = lib.mkIf config.osbmModules.hardware.nvidiaDriver.enable {
    # Enable OpenGL
    hardware.graphics = {
      enable = true;
    };

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      # Modesetting is required
      modesetting.enable = true;

      # Nvidia power management
      powerManagement.enable = false;
      powerManagement.finegrained = false;

      # Use the open source kernel module
      open = false;

      # Enable the Nvidia settings menu
      nvidiaSettings = true;

      # Select appropriate driver version
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Enable nvidia-container-toolkit if virtualization is enabled
    hardware.nvidia-container-toolkit.enable = lib.mkIf config.osbmModules.virtualization.docker.enable true;
  };
}
