{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../../../modules/nixos/options.nix
    ../../../modules/nixos/programs/command-line.nix
    ../../../modules/nixos/programs/neovim.nix
    ../../../modules/nixos/system/nix-settings.nix
    inputs.home-manager.darwinModules.home-manager
  ];

  osbmModules = {
    programs.neovim.enable = true;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    backupFileExtension = "hmbak";
    users.osbm = {
      imports = [ ../../../modules/home-manager ];
      home.stateVersion = "24.11";
    };
  };

  services.tailscale = {
    enable = true;
  };

  programs.fish.enable = true;

  # osbmModules.setUsers = false;
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
