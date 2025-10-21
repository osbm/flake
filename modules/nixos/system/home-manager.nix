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

  config = lib.mkMerge [
    (lib.mkIf (config.osbmModules.homeManager.enable) {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        # Pass inputs and outputs to home-manager modules
        extraSpecialArgs = { inherit inputs; };

        # Configure home-manager for each user (excluding root)
        users = 
          let
            # Capture the NixOS system config before entering the home-manager scope
            systemConfig = config;
          in
          lib.genAttrs (builtins.filter (u: u != "root") config.osbmModules.users) (username: {
            home.stateVersion = lib.mkDefault "24.05";
            imports = [ 
              ../../home-manager 
            ] 
            ++ lib.optionals systemConfig.osbmModules.hardware.disko.zfs.root.impermanenceRoot [
              # Import impermanence home-manager module when impermanence is enabled
              inputs.impermanence.homeManagerModules.impermanence
              # Configure persistence
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
    })
  ];
}
