{pkgs, inputs, lib, config, ...}: {
  imports = [
    # ../../modules
    ../../modules/common-packages.nix
    ../../modules/nix-settings.nix
    inputs.home-manager.darwinModules.home-manager
    ./dummy-module.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    backupFileExtension = "hmbak";
    users.mac = import ../../home/home.nix {
      inherit config pkgs;
      username = "mac";
      homeDirectory = "/Users/mac";
      stateVersion = "24.11";
    };
  };

  programs.fish.enable = true;

  # myModules.setUsers = false;
  users.users.mac = {
    description = "mac";
    shell = pkgs.fish;
    home = "/Users/mac";
  };
  environment.systemPackages = with pkgs; [
    alacritty
    ghostty
    kitty
    vscode
    blender
    libreoffice
    code-cursor
    ungoogled-chromium
  ];
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "x86_64-darwin";
}
