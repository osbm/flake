{ lib, config, ... }:
let
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
    enableCaddy = true;
    enableAttic = true;
    enableCloudflared = true;
  };

  services.caddy.virtualHosts = {
    "${wallfacerTailscaleDomain}" = {
      extraConfig = ''
        handle_path /hydra/* {
          reverse_proxy localhost:${toString config.services.hydra.port}
        }
        handle_path /nextcloud/* {
          respond "Nextcloud is not configured yet. Please set up the service."
        }
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ config.services.hydra.port ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  i18n.inputMethod.enable = lib.mkForce false;
  networking.hostName = "wallfacer";
  system.stateVersion = "25.05";
}
