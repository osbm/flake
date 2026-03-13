{
  config,
  lib,
  pkgs,
  ...
}:
let
  hostname = config.networking.hostName;
  cfg = config.osbmModules.services.syncthing;

  allFolders = {
    "music" = {
      path = "/home/osbm/Music";
      devices = [
        "wallfacer"
        "ymir"
        "tartarus"
        "luoji"
        "ares"
        "artemis"
        # "puck"
        # "atreus"
      ];
    };
    "terraria" = {
      path = "/home/osbm/.local/share/Terraria";
      devices = [
        "ymir"
        "ares"
        "apollo"
      ];
      ignorePatterns = [
        "*.json"
      ];
    };
    "rerouting" = {
      path = "/home/osbm/Documents/rerouting";
      devices = [
        "ymir"
        "tartarus"
        "luoji"
        "apollo"
        "prometheus"
      ];
      ignorePatterns = [
        ".git"
        ".obsidian/workspace.json"
        ".obsidian/workspace-mobile.json"
      ];
      versioning = {
        type = "staggered";
        params = {
          cleanInterval = "3600";
          maxAge = "604800"; # Keep versions for up to 1 week (in seconds)
        };
      };
    };
  };

  # Only include folders where this host is in the device list
  myFolders = lib.filterAttrs (_: v: builtins.elem hostname v.devices) allFolders;
  folderPaths = lib.mapAttrsToList (_: v: v.path) myFolders;

  conflictWatcherScript = pkgs.writeShellScript "syncthing-conflict-watcher" ''
    CONFLICTS=""
    for folder in ${lib.concatStringsSep " " (map (p: ''"${p}"'') folderPaths)}; do
      if [ -d "$folder" ]; then
        count=$(${pkgs.findutils}/bin/find "$folder" -name "*.sync-conflict-*" -type f | wc -l)
        if [ "$count" -gt 0 ]; then
          CONFLICTS+="$folder: $count conflict(s) found.\n"
        fi
      fi
    done

    if [ -n "$CONFLICTS" ]; then
      ${pkgs.curl}/bin/curl -sf \
        -H "Title: Syncthing Conflict Detected on $(hostname)" \
        -H "Tags: warning,syncthing" \
        -d "$CONFLICTS" \
        "https://ntfy.osbm.dev/syncthing-conflicts" || true
    fi
  '';
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
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
            globalAnnounceEnabled = false;
          };
          folders = myFolders;
          devices =
            builtins.mapAttrs
              (name: id: {
                inherit id;
                addresses = [ "tcp://${name}:22000" ];
              })
              {
                wallfacer = "L7LZQ4A-SXV6NAQ-EZII4HQ-DEUHHJG-HE57CJA-S3OZ7FI-5MACY26-M5LQFQH";
                pochita = "KHRI624-S7YHFJJ-KX7IATC-QFSS6X6-U2OUDN3-HWREAVI-7ABRS4P-SUSK6A6";
                luoji = "54O4Q42-GXACXO6-BK7TF4Q-NVBW6OF-ODPPVWO-WLW43CV-ZZEZXQD-JUAF7AY";
                ymir = "BDBLJP4-ANZ46I6-4YVIU7K-GXPYGGG-JIVKGZ6-BUNH2YD-HBYBYC3-NNC5FAU";
                tartarus = "SBBZZOL-IJ7PTAK-4LB6SPE-QKQZ2I2-62HVQSV-MN3C7JL-WHUTA2K-SVDGPA6";
                ares = "U6AVFUV-NBSJHAK-NX2IAH5-KMSK5NY-D3NEYV4-O7PG2FZ-F3DMWLH-BD732QS";
                artemis = "SGXJ4VY-R3S5LLZ-I3WQ5CE-XJYRKSF-PAL5H5O-CICMUGQ-QTX74MY-X4P2NAK";
                apollo = "3PADNDM-IC43RZA-B2CWAYW-QDYED23-VMEHSK7-CZYTAYD-BVP5I3K-MNDABAU";
                prometheus = "TODRPTH-HALIAQS-UC543ZV-I6WRHUB-ISU4OFU-JXCTPB3-BYMQAQV-7XIM6A4";
                # atreus = "ATREUS-DEVICE-ID";
                # puck = "PUCK-DEVICE-ID";
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

    (lib.mkIf (cfg.enable && cfg.conflictAlerts.enable) {
      systemd.services.syncthing-conflict-watcher = {
        description = "Syncthing Conflict Watcher";
        serviceConfig = {
          Type = "oneshot";
          User = "osbm";
          ExecStart = conflictWatcherScript;
        };
      };

      systemd.timers.syncthing-conflict-watcher = {
        description = "Check for Syncthing conflicts hourly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };
    })
  ];
}
