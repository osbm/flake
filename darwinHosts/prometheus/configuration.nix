{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [
    # ../../modules
    ../../modules/common-packages.nix
    # inputs.home-manager-darwin.darwinModules.home-manager
    inputs.home-manager.darwinModules.home-manager
    ./dummy-module.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    backupFileExtension = "hmbak";
    users.osbm = import ../../home/home.nix {
      inherit config pkgs;
      username = "osbm";
      homeDirectory = "/Users/osbm";
      stateVersion = "24.11";
      enableGTK = false;
      enableGhostty = false;
    };
  };
  nix.registry = {
    nixpkgs.to.path = lib.mkForce inputs.nixpkgs;
  };
  services.tailscale = {
    enable = true;
  };

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
    "mac" # TODO change mac user to osbm
  ];

  # nix.nixPath = ["nixpkgs=${pkgs.path}"];

  system.configurationRevision = inputs.self.rev or "dirty";

  programs.fish.enable = true;

  # myModules.setUsers = false;
  users.users.osbm = {
    description = "osbm";
    shell = pkgs.fish;
    home = "/Users/osbm";
  };
  environment.systemPackages = with pkgs; [
    alacritty
    # ghostty
    kitty
    vscode
    git
    lazygit
    # blender
    # libreoffice
    # ungoogled-chromium
    code-cursor
    ollama
  ];
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "x86_64-darwin";
}
