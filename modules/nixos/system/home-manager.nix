{
  lib,
  config,
  inputs,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  config = lib.mkIf (config.osbmModules.homeManager.enable) {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;

      # Pass inputs and outputs to home-manager modules
      extraSpecialArgs = { inherit inputs; };

      # Configure home-manager for each user (excluding root)
      users = lib.genAttrs (builtins.filter (u: u != "root") config.osbmModules.users) (username: {
        home.stateVersion = lib.mkDefault "24.05";
        imports = [ 
          ../../home-manager 
        ] ++ lib.optionals config.osbmModules.hardware.disko.zfs.impermanence.enable [
          # if impermanence is enabled, configure persistence
          {
            home.persistence."/persist/home/${username}" = {
              directories = [
                "Pictures"
                "Documents"
                "Videos"
                ".gnupg"
                ".ssh"
                ".local/share/keyrings"
                ".local/share/direnv"
                # {
                #   directory = ".local/share/Steam";
                #   method = "symlink";
                # }
              ];
              files = [
                ".screenrc"
              ];
              allowOther = true;
            };
          }
        ];
      });
    };
  };
}
