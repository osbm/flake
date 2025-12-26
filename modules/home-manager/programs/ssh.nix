let
  # define a block that just takes a hostname and returns attrset to not repeat the same fields
  sshBlock = hostname: {
    inherit hostname;
    user = "osbm";
    identityFile = "~/.ssh/id_ed25519";
    extraOptions = {
      # [ERROR] - (starship::print): Under a 'dumb' terminal (TERM=dumb).
      "RemoteCommand" = "fish";
      "RequestTTY" = "force";
    };
    hashKnownHosts = true;
    compression = true;
  };
  # sshBlockDroid is the same as sshBlock but with 8090 as the port
  sshBlockDroid = hostname: {
    inherit hostname;
    user = "osbm";
    identityFile = "~/.ssh/id_ed25519";
    port = 8022;
    hashKnownHosts = true;
    compression = true;
    # fish not found error ???
  };
  sshBlockAlgorynth = hostname: {
    inherit hostname;
    user = "algorynth";
    identityFile = "~/.ssh/id_ed25519";
    hashKnownHosts = true;
    compression = true;
  };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
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
        hostname = "152.53.152.129";
        port = 2222;
        user = "root";
        identityFile = "~/.ssh/id_ed25519";
        hashKnownHosts = true;
        compression = true;
      };
      ares = sshBlock "192.168.0.6";
      ares-ts = sshBlock "ares.curl-boga.ts.net";
      luoji = sshBlockDroid "192.168.0.7";
      luoji-ts = sshBlockDroid "luoji.curl-boga.ts.net";
      # artemis
      # Algorynth infrastructure
      huginn = sshBlockAlgorynth "159.195.69.95";
      huginn-ts = sshBlockAlgorynth "huginn.curl-boga.ts.net";
    };
  };
}
