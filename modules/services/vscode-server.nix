{config, ...}: {
  services.code-server = {
    enable = true;
    port = 4444;
    disableTelemetry = true;
    disableUpdateCheck = true;
    user = "osbm";
    host = "${config.networking.hostName}.curl-boga.ts.net";
    hashedPassword = "$argon2i$v=19$m=4096,t=3,p=1$dGc0TStGMDNzSS9JRkJYUFp3d091Q2p0bXlzPQ$zvdE9BkclkJmyFaenzPy2E99SEqsyDMt4IQNZfcfFFQ";
  };
  networking.firewall.allowedTCPPorts = [config.services.code-server.port];
}
