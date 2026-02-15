{
  inputs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.osbmModules.nixSettings.enable {
    # Allow unfree packages
    osbmModules.nixSettings.allowedUnfreePackages = [
      "vscode-extension-github-copilot"
      "spotify"
      "cursor"
      # blender with cuda is not foss?!?
      "blender"
    ];

    nixpkgs = {
      config = {
        allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) config.osbmModules.nixSettings.allowedUnfreePackages;
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
