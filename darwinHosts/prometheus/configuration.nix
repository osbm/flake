{pkgs, ...}: {
  imports = [
    # ../../modules
    ../../modules/common-packages.nix
    ../../modules/home.nix
    ../../modules/nix-settings.nix
    ../../modules/secrets.nix
  ];

  myModules.setUsers = false;
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
