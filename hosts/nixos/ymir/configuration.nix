{
  pkgs,
  inputs,
  ...
}:
let
  hermesPkg = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # upstream #61443: nix/desktop.nix hardcodes the electron node-headers
  # hash, and electronjs.org re-published the v41.9.1 tarball, so the build
  # fails with a hash mismatch. Re-import a hash-corrected copy of that one
  # file, feeding it the passthru pieces from the already-locked package —
  # no extra flake input, and the agent itself is untouched. Drop when
  # upstream fixes desktop.nix.
  patchedDesktopNix = builtins.toFile "hermes-desktop-fixed.nix" (
    builtins.replaceStrings
      [ "sha256-zi/QMwRZ0+FwE9XTE+DiSIeJXAwxmLKEaBWD5W3pMOI=" ]
      [ "sha256-zOl8rx6woWh7aeRUOlkTMviKc/EAQQX6nr/MxAx1ZPI=" ]
      (builtins.readFile "${inputs.hermes-agent}/nix/desktop.nix")
  );
  hermes-desktop = pkgs.callPackage patchedDesktopNix {
    inherit (hermesPkg) hermesNpmLib;
    hermesAgent = hermesPkg;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
  ];

  # hermes desktop GUI (Electron shell), connects in remote mode to the
  # gateway on apollo (https://hermes.osbm.dev) — no local agent runtime
  # needed for that. Terminal access to the same agent: `ssh -t apollo hermes`.
  environment.systemPackages = [ hermes-desktop ];

  osbmModules = {
    desktopEnvironment = {
      plasma.enable = true;
      niri.enable = true;
      # hyprland.enable = true; # im insane so i enable every DE
    };
    familyUser.enable = true;
    programs = {
      steam.enable = true;
    };
    emulation.aarch64.enable = true;
    virtualisation.docker.enable = true;
    hardware = {
      hibernation.enable = false;
      wakeOnLan.enable = true;
      sound.enable = true;
      nvidia.enable = true;
    };
    services = {
      ollama.enable = true;
      syncthing.enable = true;

      # Backup client - pulls vaultwarden backup from apollo
      backup-client = {
        enable = true;
        backups = {
          apollo-vaultwarden = {
            remoteHost = "apollo";
            localPath = "/var/backups/apollo-vaultwarden";
            services = [ "vaultwarden" ];
          };
        };
      };
    };
    i18n.enable = true;
  };

  networking = {
    hostName = "ymir";

    firewall.allowedTCPPorts = [
      8889
      8000
    ];

    networkmanager.enable = true;
  };

  # services.displayManager.autoLogin = {
  #   enable = true;
  #   user = "osbm";
  # };

  # virtualisation.waydroid.enable = true;

  system.stateVersion = "25.05"; # changing this is a great taboo of the nixos world
}
