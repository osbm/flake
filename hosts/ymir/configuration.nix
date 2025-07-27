{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  myModules = {
    blockYoutube = false;
    blockTwitter = true;
    blockBluesky = false;
    enableKDE = true;
    enableJellyfin = true;
    enableAarch64Emulation = true;
    disableHibernation = true;
    enableWakeOnLan = true;
    enableSound = true;
    enableADB = true;
    enableOllama = true;
    enableMinegrubTheme = true;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ymir"; # Define your hostname.


  networking.firewall.allowedTCPPorts = [
    8889
    8000
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  hardware.nvidia-container-toolkit.enable = true;

  # Enable OpenGL
  programs.nix-required-mounts.enable = true;
  programs.nix-required-mounts.presets.nvidia-gpu.enable = true;

  hardware.graphics = {
    enable = true;
  };

  virtualisation.waydroid.enable = true;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
  ];

  system.stateVersion = "25.05"; # great taboo of the nixos world
}
