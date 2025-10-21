{ lib, config, ... }:
{
  config = lib.mkIf config.osbmModules.i18n.enable {
    # Set your time zone
    time.timeZone = lib.mkDefault "Europe/Istanbul";

    # Select internationalisation properties
    i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

    i18n.extraLocaleSettings = lib.mkDefault {
      LC_ADDRESS = "tr_TR.UTF-8";
      LC_IDENTIFICATION = "tr_TR.UTF-8";
      LC_MEASUREMENT = "tr_TR.UTF-8";
      LC_MONETARY = "tr_TR.UTF-8";
      LC_NAME = "tr_TR.UTF-8";
      LC_NUMERIC = "tr_TR.UTF-8";
      LC_PAPER = "tr_TR.UTF-8";
      LC_TELEPHONE = "tr_TR.UTF-8";
      LC_TIME = "ja_JP.UTF-8";
    };
  };
}
