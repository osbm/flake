{ pkgs, ... }:
{

  services.gpg-agent = {
    enable = true;
    enableFishIntegration = true;
    enableSshSupport = true;
    # extraConfig = ''
    #   allow-loopback-pinentry
    # '';
    pinentry.package = pkgs.pinentry-tty;
  };
  programs.gpg.enable = true;
  # home.packages = [ pkgs.pinentry-curses ];
}
