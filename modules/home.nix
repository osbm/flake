{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    backupFileExtension = "hmbak";
    users.osbm = import ../home/home.nix {
      inherit config pkgs;
      # fuck you macos
      username = "osbm";
      homeDirectory = "/home/osbm";
      inherit (config.system) stateVersion;
    };
  };
}
