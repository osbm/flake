{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.syncthing.enable {
      services.syncthing = {
        enable = true;
        user = "osbm";
        dataDir = "/home/osbm";
        openDefaultPorts = false;
        guiAddress = "0.0.0.0:8384";
        # port is 8384
        settings = {
          gui = {
            theme = "black";
            user = "osbm";
            password = "$2b$05$tpqRn4OcpQoyewzIUPtTIOqA6LPntB5ItID.wF1OBmX9d5IUDVJX6";
          };
          options = {
            urAccepted = -1; # Disable usage reporting
            crashReportingEnabled = false;
          };
          folders = {
            "music" = {
              path = "/home/osbm/Music";
              devices = [
                "wallfacer"
                "pochita"
                "ymir"
                "tartarus"
                "luoji"
                "ares"
                # "artemis"
                # "puck"
                # "atreus"
              ];
            };
          };
          devices = {
            wallfacer = {
              id = "L7LZQ4A-SXV6NAQ-EZII4HQ-DEUHHJG-HE57CJA-S3OZ7FI-5MACY26-M5LQFQH";
            };
            pochita = {
              id = "KHRI624-S7YHFJJ-KX7IATC-QFSS6X6-U2OUDN3-HWREAVI-7ABRS4P-SUSK6A6";
            };
            luoji = {
              id = "54O4Q42-GXACXO6-BK7TF4Q-NVBW6OF-ODPPVWO-WLW43CV-ZZEZXQD-JUAF7AY";
            };
            ymir = {
              id = "BDBLJP4-ANZ46I6-4YVIU7K-GXPYGGG-JIVKGZ6-BUNH2YD-HBYBYC3-NNC5FAU";
            };
            tartarus = {
              id = "SBBZZOL-IJ7PTAK-4LB6SPE-QKQZ2I2-62HVQSV-MN3C7JL-WHUTA2K-SVDGPA6";
            };
            ares = {
              id = "U6AVFUV-NBSJHAK-NX2IAH5-KMSK5NY-D3NEYV4-O7PG2FZ-F3DMWLH-BD732QS";
            };
            # artemis = {
            #   id = "ARTEMIS-DEVICE-ID"; # Replace with actual ID from artemis
            # };
            # atreus = {
            #   id = "ATREUS-DEVICE-ID"; # Replace with actual ID from atreus
            # };
            # puck = {
            #   id = "PUCK-DEVICE-ID"; # Replace with actual ID from puck
            # };
          };
        };
      };

      # Open Syncthing ports only on Tailscale interface
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        8384
        22000
      ];
      networking.firewall.interfaces.tailscale0.allowedUDPPorts = [
        22000
        21027
      ];
    })
  ];
}
