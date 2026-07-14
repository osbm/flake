{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
    inputs.raspberry-pi-nix.nixosModules.sd-image
  ];
  # bcm2711 for rpi 3, 3+, 4, zero 2 w
  # bcm2712 for rpi 5
  # See the docs at:
  # https://www.raspberrypi.com/documentation/computers/linux_kernel.html#native-build-configuration
  raspberry-pi-nix.board = "bcm2712";

  # nixpkgs's hardware.deviceTree.enable default reads
  # config.boot.kernelPackages.kernel.buildDTBs, which raspberry-pi-nix's
  # kernel doesn't expose. Set it explicitly to bypass the broken default.
  hardware.deviceTree.enable = true;

  # Same story: system.boot.loader.kernelFile defaults to
  # config.boot.kernelPackages.kernel.target, which raspberry-pi-nix's kernel
  # also doesn't expose. "Image" is the aarch64 value the old default used.
  system.boot.loader.kernelFile = "Image";

  # systemd-in-initrd hangs on Pi 5; legacy script initrd works
  boot.initrd.systemd.enable = false;

  # RPi kernel doesn't have tpm-crb module
  boot.initrd.systemd.tpm2.enable = false;

  time.timeZone = "America/Chicago";
  users.users.root = {
    initialPassword = "root";
  };
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.osbm = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    initialPassword = "changeme";
  };

  networking = {
    hostName = "pochita";
  };
  environment.systemPackages = with pkgs; [
    neovim
    git-lfs
    git
    wakeonlan
    htop
    unzip
    zip
    wget
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.trusted-users = [
    "root"
    "osbm"
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  services.openssh = {
    enable = true;
  };
  system.stateVersion = "25.05";
}
