{ ... }:
let
  # define a block that just takes a hostname and returns attrset to not repeat the same fields
  sshBlock = hostname: {
    hostname = hostname;
    user = "osbm";
    identityFile = "/home/osbm/.ssh/id_ed25519";
    extraOptions = {
      # [ERROR] - (starship::print): Under a 'dumb' terminal (TERM=dumb).
      "RemoteCommand" = "fish";
      "RequestTTY" = "force";
    };
    hashKnownHosts = true;
    compression = true;
  };
  # sshBlockAtreus is the same as sshBlock but with 8090 as the port
  sshBlockAtreus = hostname: {
    hostname = hostname;
    user = "osbm";
    identityFile = "/home/osbm/.ssh/id_ed25519";
    port = 8022;
    hashKnownHosts = true;
    compression = true;
    # fish not found error ???
  };
in
{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      ymir = sshBlock "192.168.0.2";
      ymir-ts = sshBlock "ymir.curl-boga.ts.net";
      atreus = sshBlockAtreus "192.168.0.3";
      atreus-ts = sshBlockAtreus "atreus.curl-boga.ts.net";
      tartarus = sshBlock "192.168.0.4";
      tartarus-ts = sshBlock "tartarus.curl-boga.ts.net";
      pochita = sshBlock "192.168.0.9";
      pochita-ts = sshBlock "pochita.curl-boga.ts.net";
      harmonica = sshBlock "192.168.0.11";
      harmonica-ts = sshBlock "harmonica.curl-boga.ts.net";
      wallfacer = sshBlock "192.168.0.5";
      wallfacer-ts = sshBlock "wallfacer.curl-boga.ts.net";
    };
  };
}
