{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.osbmModules.services.alloy.enable {
    services.alloy = {
      enable = true;
    };

    environment.etc."alloy/config.alloy".text = ''
      loki.source.journal "systemd" {
        max_age      = "12h"
        forward_to   = [loki.write.default.receiver]
        relabel_rules = loki.relabel.journal.rules
        labels       = {
          job  = "systemd-journal",
          host = "${config.networking.hostName}",
        }
      }

      loki.relabel "journal" {
        forward_to = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
      }

      loki.write "default" {
        endpoint {
          url = "${config.osbmModules.services.alloy.lokiUrl}/loki/api/v1/push"
        }
      }
    '';
  };
}
