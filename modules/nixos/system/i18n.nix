{
  lib,
  pkgs,
  config,
  ...
}:
{
  config = lib.mkIf config.osbmModules.i18n.enable {
    time.timeZone = lib.mkDefault "Europe/Istanbul";

    # Select internationalisation properties.
    i18n = {
      defaultLocale = "en_US.UTF-8";

      extraLocaleSettings = {
        LC_ADDRESS = "tr_TR.UTF-8";
        LC_IDENTIFICATION = "tr_TR.UTF-8";
        LC_MEASUREMENT = "tr_TR.UTF-8";
        LC_MONETARY = "tr_TR.UTF-8";
        LC_NAME = "tr_TR.UTF-8";
        LC_NUMERIC = "tr_TR.UTF-8";
        LC_PAPER = "tr_TR.UTF-8";
        LC_TELEPHONE = "tr_TR.UTF-8";
        LC_TIME = "ja_JP.UTF-8";
        # LC_ALL = "en_US.UTF-8";
      };

      inputMethod = {
        type = "fcitx5";
        enable = config.osbmModules.desktopEnvironment != "none";
        fcitx5.addons = with pkgs; [
          fcitx5-mozc
          fcitx5-gtk
          fcitx5-nord # a color theme
        ];
      };
    };

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

  };
}
