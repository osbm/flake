{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];
  programs.nix-index-database.comma.enable = true;
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
    nixpkgs.flake = inputs.nixpkgs;
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

  nix.gc = {
    automatic = true;
    dates = "01:37";
    options = "--delete-older-than 7d";
  };

  # nix.nixPath = ["nixpkgs=${pkgs.path}"];

  # disable the database error TODO add nix-index search
  programs.command-not-found.enable = false;

  system.configurationRevision = inputs.self.rev or "dirty";
}
