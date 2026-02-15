{
  inputs,
  lib,
  config,
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
      };

      optimise.automatic = true;

      channel.enable = false;

      registry = lib.mkIf (inputs ? self && inputs ? nixpkgs) {
        self.flake = inputs.self;
        nixpkgs.flake = inputs.nixpkgs;
        osbm-nvim = lib.mkIf (inputs ? osbm-nvim) {
          flake = inputs.osbm-nvim;
        };
      };
    };

    system.configurationRevision = inputs.self.rev or "dirty";
  };
}
