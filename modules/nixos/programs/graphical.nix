{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.osbmModules.programs.graphical.enable {
    environment.systemPackages = with pkgs; [
      mpv
      gimp
      inkscape
      libreoffice
      discord
      telegram-desktop
      obs-studio
      blender
      vscode
      chromium
    ];
  };
}
