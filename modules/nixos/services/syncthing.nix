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
  # (conflict alerting moved to prometheus rules; conflicts are counted by the
  # metrics exporter below and alerted via alertmanager -> ntfy-relay)
  # Exports syncthing state as node-exporter textfile metrics. Reads the API
  # key locally from config.xml, so no secrets live in the repo.
  metricsScript = pkgs.writeScript "syncthing-metrics" ''
    #!${pkgs.python3}/bin/python3
    import json, os, re, urllib.request

    OUT = "/var/lib/node-exporter/syncthing.prom"
    cfg = open("/home/osbm/.syncthing/config.xml").read()
    key = re.search(r"<apikey>([^<]+)</apikey>", cfg).group(1)

    def get(path):
        req = urllib.request.Request("http://localhost:8384" + path, headers={"X-API-Key": key})
        with urllib.request.urlopen(req, timeout=10) as r:
            return json.load(r)

    lines = []
    try:
        devices = {d["deviceID"]: d["name"] for d in get("/rest/config/devices")}
        conns = get("/rest/system/connections")["connections"]
        for did, c in conns.items():
            name = devices.get(did, did[:7])
            lines.append(f'syncthing_device_connected{{device="{name}"}} {1 if c["connected"] else 0}')
        for f in get("/rest/config/folders"):
            fid, path = f["id"], f["path"]
            st = get(f"/rest/db/status?folder={fid}")
            lines.append(f'syncthing_folder_need_items{{folder="{fid}"}} {st.get("needTotalItems", 0)}')
            lines.append(f'syncthing_folder_need_bytes{{folder="{fid}"}} {st.get("needBytes", 0)}')
            lines.append(f'syncthing_folder_errors{{folder="{fid}"}} {st.get("errors", 0)}')
            conflicts = 0
            for root, _, files in os.walk(os.path.expanduser(path)):
                conflicts += sum(1 for n in files if ".sync-conflict-" in n)
            lines.append(f'syncthing_folder_conflict_files{{folder="{fid}"}} {conflicts}')
        lines.append("syncthing_up 1")
    except Exception:
        lines.append("syncthing_up 0")

    with open(OUT + ".tmp", "w") as fh:
        fh.write("\n".join(lines) + "\n")
    os.replace(OUT + ".tmp", OUT)
  '';
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.syncthing = {
        enable = true;
        user = "osbm";
        dataDir = "/home/osbm";
        configDir = "/home/osbm/.syncthing";
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
                # IDs re-verified 2026-09-04 (ymir/pochita/wallfacer had regenerated
                # identities; old IDs caused months of "unknown device" rejections)
                wallfacer = "637HJBQ-MJPJCVC-2ULZR32-OOAGFKZ-EJNIYGE-3IG67SL-OTL5T5L-GHWL6AE";
                pochita = "MMTR7XX-CETSB5B-LFPBN7S-A4ASTRW-J2DYX72-SAJTZVM-XLYBLR7-BEPSGAK";
                luoji = "54O4Q42-GXACXO6-BK7TF4Q-NVBW6OF-ODPPVWO-WLW43CV-ZZEZXQD-JUAF7AY";
                ymir = "S2EJFTI-FKJYEDG-YXUKO3P-BQ23D32-GFCEBJV-6MSDZ73-MYJFDE7-N437XQ3";
                tartarus = "SBBZZOL-IJ7PTAK-4LB6SPE-QKQZ2I2-62HVQSV-MN3C7JL-WHUTA2K-SVDGPA6";
                ares = "U6AVFUV-NBSJHAK-NX2IAH5-KMSK5NY-D3NEYV4-O7PG2FZ-F3DMWLH-BD732QS";
                artemis = "SGXJ4VY-R3S5LLZ-I3WQ5CE-XJYRKSF-PAL5H5O-CICMUGQ-QTX74MY-X4P2NAK";
                apollo = "7PVG2VU-WVS2LZZ-SIOJ23J-TG32BYM-WBAA6T5-462GXRU-AHSFA77-VVFPLQZ";
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

    (lib.mkIf (cfg.enable && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot) {
      environment.persistence."/persist".users.osbm = {
        directories = [
          {
            directory = ".syncthing";
            mode = "0700";
          }
        ];
      };
    })

    # Syncthing metrics -> node-exporter textfile collector -> existing
    # prometheus "node" job on apollo. No new scrape configs, no repo secrets.
    (lib.mkIf (cfg.enable && config.osbmModules.services.node-exporter.enable) {
      systemd.services.syncthing-metrics = {
        description = "Export syncthing state for node-exporter";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = metricsScript;
          ReadWritePaths = [ "/var/lib/node-exporter" ];
        };
      };
      systemd.timers.syncthing-metrics = {
        description = "Timer for syncthing metrics export";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "2min";
        };
      };
    })

  ];
}
