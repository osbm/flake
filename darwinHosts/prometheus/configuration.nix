{pkgs, ...}: {
  imports = [
    ../../modules
  ];

  system.stateVersion = 6;
  nixpkgs.hostPlatform = "x86_64-darwin";
}
