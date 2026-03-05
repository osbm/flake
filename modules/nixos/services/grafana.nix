{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.osbmModules.services.grafana.enable {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
        };
        security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://apollo.curl-boga.ts.net:9090";
            isDefault = true;
          }
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://localhost:3100";
          }
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [ 3000 ];
  };
}
