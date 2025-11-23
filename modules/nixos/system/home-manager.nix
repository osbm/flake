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
    # Enable FUSE user_allow_other when impermanence is used
    (lib.mkIf config.osbmModules.hardware.disko.zfs.root.impermanenceRoot {
      programs.fuse.userAllowOther = true;
    })

    (lib.mkIf config.osbmModules.homeManager.enable {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = ".nixbak";

        # Pass inputs and outputs to home-manager modules
        extraSpecialArgs = {
          inherit inputs;
          # Pass the NixOS system config to home-manager modules
          nixosConfig = config;
        };

        # Configure home-manager for each user (excluding root)
        users =
          let
            # Capture the NixOS system config before entering the home-manager scope
            systemConfig = config;
            # Build list of regular users based on defaultUser and familyUser options
            regularUsers = [
              systemConfig.osbmModules.defaultUser
            ]
            ++ lib.optional systemConfig.osbmModules.familyUser.enable "bayram";
          in
          lib.genAttrs regularUsers (_username: {
            # Use the system's stateVersion for home-manager
            home.stateVersion = lib.mkDefault systemConfig.system.stateVersion;
            imports = [
              ../../home-manager
            ]
            ++ lib.optionals systemConfig.osbmModules.hardware.disko.zfs.root.impermanenceRoot [
              # Import impermanence home-manager module when impermanence is enabled
              inputs.impermanence.homeManagerModules.impermanence
            ];
          });
      };
    })
  ];
}
