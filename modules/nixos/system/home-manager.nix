{ lib, config, inputs, ... }:
let
  cfg = config.osbmModules;
in
{
  config = lib.mkIf (cfg.homeManager.enable && inputs ? home-manager) {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;

      # Pass inputs and outputs to home-manager modules
      extraSpecialArgs = { inherit inputs; };

      # Configure home-manager for each user
      users = lib.genAttrs cfg.users (username: {
        home.stateVersion = lib.mkDefault "24.05";
        imports = [ ../../home-manager ];
      });
    };
  };
}
