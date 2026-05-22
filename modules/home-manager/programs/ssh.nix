let
  sshBlock = hostname: {
    HostName = hostname;
    User = "osbm";
    IdentityFile = "~/.ssh/id_ed25519";
    HashKnownHosts = true;
    Compression = true;
  };
  sshBlockDroid = hostname: {
    HostName = hostname;
    User = "osbm";
    IdentityFile = "~/.ssh/id_ed25519";
    Port = 8022;
    HashKnownHosts = true;
    Compression = true;
  };
  sshBlockAlgorynth = hostname: {
    HostName = hostname;
    User = "algorynth";
    IdentityFile = "~/.ssh/id_ed25519";
    HashKnownHosts = true;
    Compression = true;
  };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      ymir = sshBlock "192.168.0.2";
      ymir-ts = sshBlock "ymir.curl-boga.ts.net";
      atreus = sshBlockDroid "192.168.0.3";
      atreus-ts = sshBlockDroid "atreus.curl-boga.ts.net";
      tartarus = sshBlock "192.168.0.4";
      tartarus-ts = sshBlock "tartarus.curl-boga.ts.net";
      pochita = sshBlock "192.168.0.9";
      pochita-ts = sshBlock "pochita.curl-boga.ts.net";
      harmonica = sshBlock "192.168.0.11";
      harmonica-ts = sshBlock "harmonica.curl-boga.ts.net";
      wallfacer = sshBlock "192.168.0.5";
      wallfacer-ts = sshBlock "wallfacer.curl-boga.ts.net";
      prometheus = sshBlock "192.168.0.12";
      prometheus-ts = sshBlock "prometheus.curl-boga.ts.net";
      apollo = sshBlock "152.53.152.129";
      apollo-ts = sshBlock "apollo.curl-boga.ts.net";
      apollo-initrd = {
        HostName = "152.53.152.129";
        Port = 2222;
        User = "root";
        IdentityFile = "~/.ssh/id_ed25519";
        HashKnownHosts = true;
        Compression = true;
        RequestTTY = "yes";
        RemoteCommand = "systemd-tty-ask-password-agent --query";
      };
      ares = sshBlock "192.168.0.6";
      ares-ts = sshBlock "ares.curl-boga.ts.net";
      artemis = sshBlock "192.168.0.13";
      artemis-ts = sshBlock "artemis.curl-boga.ts.net";
      luoji = sshBlockDroid "192.168.0.7";
      luoji-ts = sshBlockDroid "luoji.curl-boga.ts.net";
      # Algorynth infrastructure
      huginn = sshBlockAlgorynth "159.195.69.95";
      huginn-ts = sshBlockAlgorynth "huginn.curl-boga.ts.net";
      puck = sshBlock "puck.curl-boga.ts.net";
    };
  };
}
