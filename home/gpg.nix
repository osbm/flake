{

  services.gpg-agent = {
    enable = true;
    enableFishIntegration = true;
    enableSshSupport = true;
    extraConfig = ''
      allow-loopback-pinentry
    '';
    pinentry.program = "pinentry-wayprompt";
  };
  programs.gpg.enable = true;
}
