{

  services.gpg-agent = {
    enable = true;
    enableFishIntegration = true;
    enableSshSupport = true;
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };
  programs.gpg.enable = true;
}
