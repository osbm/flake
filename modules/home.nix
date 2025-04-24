{
  config,
  pkgs,
  ...
}: {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.osbm = import ../home/home.nix {
    inherit config pkgs;
    backupFileExtension = "hmbak";
  };
}
