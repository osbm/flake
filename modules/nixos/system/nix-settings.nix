{
  inputs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.osbmModules.nixSettings.enable {
    # Allow unfree packages
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "vscode"
        "discord"
        "obsidian"
        "steam"
        "steam-unwrapped"
        "open-webui"
        "vscode-extension-github-copilot"
        "spotify"
        "cursor"
        # NVIDIA related
        "nvidia-x11"
        "cuda_cudart"
        "libcublas"
        "cuda_cccl"
        "cuda_nvcc"
        "nvidia-settings"
        "cuda-merged"
      ];

    nixpkgs.config.allowAliases = false;

    # Enable Nix flakes
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    nix.channel.enable = false;

    # Nix registry configuration
    nix.registry = lib.mkIf (inputs ? self && inputs ? nixpkgs) {
      self.flake = inputs.self;
      nixpkgs.flake = inputs.nixpkgs;
      osbm-nvim = lib.mkIf (inputs ? osbm-nvim) {
        flake = inputs.osbm-nvim;
      };
    };

    # Trusted users
    nix.settings.trusted-users = [
      "root"
      config.osbmModules.defaultUser
    ];

    # Binary cache configuration
    nix.settings = {
      substituters = [
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # Garbage collection
    nix.gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 7d";
    };

    # Optimize store automatically
    nix.optimise.automatic = true;

    system.configurationRevision = inputs.self.rev or "dirty";

  };
}
