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
    inputs.nix-index-database.darwinModules.nix-index
    inputs.home-manager.darwinModules.home-manager
  ];

  osbmModules = {
    programs.neovim.enable = true;
    nixSettings.allowedUnfreePackages = [
      "cursor"
      "vscode"
      "claude-code"
    ];
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

  programs.nix-index-database.comma.enable = true;
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
    # anki
    # libreoffice
    # ungoogled-chromium
    code-cursor
    claude-code
    # ollama
  ];
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "x86_64-darwin";
}
