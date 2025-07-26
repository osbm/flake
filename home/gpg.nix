{pkgs, ...}:{

  services.gpg-agent = {
    enable = true;
    enableFishIntegration = true;
    enableSshSupport = true;
    extraConfig = ''
      allow-loopback-pinentry
    '';
    pinentry.program = "pinentry-cursor";
  };
  programs.gpg.enable = true;
  home.packages = [ pkgs.pinentry-curses ];
}
