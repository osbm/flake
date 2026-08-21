{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.osbmModules.nixSettings.enable {
    nixpkgs = {
      config = {
        allowUnfreePredicate =
          pkg: builtins.elem (lib.getName pkg) config.osbmModules.nixSettings.allowedUnfreePackages;
        allowAliases = false;
      };
    };

    # Enable Nix flakes
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          config.osbmModules.defaultUser
        ];
      };

      gc = {
        automatic = true;
        options = "--delete-older-than 7d";
      }
      # default is daily; once a week is plenty (nix-darwin 26.05 has no `dates`,
      # it takes a launchd calendar interval instead)
      // (
        if pkgs.stdenv.hostPlatform.isDarwin then
          {
            interval = {
              Weekday = 0;
              Hour = 3;
              Minute = 0;
            };
          }
        else
          { dates = "weekly"; }
      );

      optimise.automatic = true;

      channel.enable = false;

      registry = lib.mkIf (inputs ? self && inputs ? nixpkgs) {
        self.flake = inputs.self;
        # unstable no longer evaluates for x86_64-darwin, so darwin hosts get the pinned branch
        nixpkgs.flake = if pkgs.stdenv.hostPlatform.isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs;
        osbm-nvim = lib.mkIf (inputs ? osbm-nvim) {
          flake = inputs.osbm-nvim;
        };
      };
    };

    system.configurationRevision = inputs.self.rev or "dirty";
  };
}
