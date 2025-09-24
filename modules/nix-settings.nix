{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "vscode" # TODO: remove this
      "discord"
      "obsidian"
      "steam"
      "steam-unwrapped"
      "open-webui"
      "vscode-extension-github-copilot"
      "spotify"
      "cursor"
      # nvidia related (i have to)
      "nvidia-x11"
      "cuda_cudart"
      "libcublas"
      "cuda_cccl"
      "cuda_nvcc"
      "nvidia-settings"
      "cuda-merged"
    ];
  nixpkgs.config.allowAliases = false;

  # enable nix flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

  nix.channel.enable = false;

  nix.registry = {
    self.flake = inputs.self;

    # Commented out because it doesnt match if i switch a system
    # to another nixpkgs with a different flake input name
    # nixpkgs.flake = inputs.nixpkgs;
    
    nixpkgs = {
      from = { type = "indirect"; id = "nixpkgs"; };
      to = {
        path = pkgs.path;
        type = "path";
      };
    };
    
    osbm-nvim.flake = inputs.osbm-nvim;
    my-nixpkgs.to = {
      owner = "osbm";
      repo = "nixpkgs";
      type = "github";
    };
    osbm-dev.to = {
      owner = "osbm";
      repo = "osbm.dev";
      type = "github";
    };
    devshells.to = {
      owner = "osbm";
      repo = "devshells";
      type = "github";
    };
  };

  nix.settings.trusted-users = [
    "root"
    "osbm"
  ];

  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org" # nix-community cache
      # "http://wallfacer.curl-boga.ts.net:7080/main" # personal attic cache
    ];

    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # "main:2AjPdIsbKyoTGuw+4x2ZXMUT/353CXosW9pdbTQtjqw="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "01:37";
    options = "--delete-older-than 7d";
  };

  # nix.nixPath = ["nixpkgs=${pkgs.path}"];

  system.configurationRevision = inputs.self.rev or "dirty";
}
