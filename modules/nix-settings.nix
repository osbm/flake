{
  inputs,
  lib,
  ...
}: {
  # Allow unfree packages
  # nixpkgs.config.allowUnfree = true; # TODO: replace this with allowUnfreePredicate
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "vscode" # TODO: remove this
      "discord" # TODO: remove this
      "obsidian"
      "steam"
      "steam-unwrapped"
      # nvidia related (i have to)
      "nvidia-x11"
      "cuda_cudart"
      "libcublas"
      "cuda_cccl"
      "cuda_nvcc"
      "nvidia-settings"
      "cuda-merged"
    ];

  # enable nix flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  nix.nixPath = [
    "nixpkgs=${inputs.nixpkgs.path}"
    "nixos-config=${inputs.self.path}"
  ];

  nix.settings.trusted-users = ["root" "osbm"];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # nix.nixPath = ["nixpkgs=${pkgs.path}"];

  # disable the database error TODO add nix-index search
  programs.command-not-found.enable = false;

  system.configurationRevision = inputs.self.rev or "dirty";
}
