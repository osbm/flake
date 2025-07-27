{ lib, ... }:
let
  hydraPort = 54543;
  wallfacerTailscaleDomain = "wallfacer.curl-boga.ts.net";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];
  myModules = {
    enableKDE = false;
    enableFonts = false;
    # enableNextcloud = true;
    enableHydra = true;
  };

  services.caddy.virtualHosts = {
    "${wallfacerTailscaleDomain}" = {
      extraConfig = ''
        handle_path /hydra* {
          reverse_proxy localhost:${toString hydraPort}
        }
        handle_path /nextcloud* {
          retun hello "Nextcloud is not configured yet. Please set up the service.";
        }
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ hydraPort ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  i18n.inputMethod.enable = lib.mkForce false;
  networking.hostName = "wallfacer";
  system.stateVersion = "25.05";
}
