{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.osbmModules.programs.graphical.enable {
    osbmModules.nixSettings.allowedUnfreePackages = [
      # "discord"
      "vscode"
      "obsidian"
      "claude-code"
    ];

    environment.systemPackages = with pkgs; [
      mpv
      gimp
      inkscape
      libreoffice
      # discord
      telegram-desktop
      obs-studio
      blender
      vscode
      chromium
      thunderbird
      claude-code
      obsidian
    ];
  };
}
