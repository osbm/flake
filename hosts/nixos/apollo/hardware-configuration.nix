{ lib, ... }:
{
  # Disko configuration is now managed by osbmModules.hardware.disko
  # All disk configuration moved to configuration.nix

  # Required for ZFS
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
