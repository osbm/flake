{pkgs, ...}: {
  imports = [
    ../../modules
  ];
  myModules.setUsers = false;
  users.users.mac = {
    description = "mac";
    shell = pkgs.fish;
    home = "/Users/mac";
  };

  system.stateVersion = 6;
  nixpkgs.hostPlatform = "x86_64-darwin";
}
