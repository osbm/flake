{ lib, config, inputs, ... }:

{
  imports = lib.optionals (inputs ? home-manager) [
    inputs.home-manager.nixosModules.home-manager
  ];

  config = lib.mkIf (config.osbmModules.homeManager.enable && inputs ? home-manager) {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;

      # Pass inputs and outputs to home-manager modules
      extraSpecialArgs = { inherit inputs; };

      # Configure home-manager for each user (excluding root)
      users = lib.genAttrs (builtins.filter (u: u != "root") config.osbmModules.users) (username: {
        home.stateVersion = lib.mkDefault "24.05";
        imports = [ ../../home-manager ];
      });
    };
  };
}
