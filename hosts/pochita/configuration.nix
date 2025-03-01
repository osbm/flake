{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
    inputs.vscode-server.nixosModules.default
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  myModules = {
    enableKDE = false;
    enableFonts = false;
    blockYoutube = false;
    blockTwitter = false;
    enableTailscale = true;
  };

  i18n.inputMethod.enable = lib.mkForce false; # no need for japanese input method

  # enable forgejo
  services.forgejo = {
    enable = true;
    settings = {
      server = {
        DOMAIN = "git.osbm.dev";
        ROOT_URL = "https://git.osbm.dev";
      };
      service = {
        DISABLE_REGISTRATION = false;
      };
    };
  };

  # i configured so that the git.osbm.dev domain points to tailscale domain
  # git.osbm.dev -> pochita.curl-boga.ts.net
  # and i want everyone to see the repositories in the git.osbm.dev domain
  # but only i want to make changes, login, etc
  # so i disabled registration
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
        # update time to time
        # last update: 2025-03-02
        plugins = [ "github.com/caddy-dns/cloudflare@1fb64108d4debf196b19d7398e763cb78c8a0f41" ];
        hash = "sha256-3nvVGW+ZHLxQxc1VCc/oTzCLZPBKgw4mhn+O3IoyiSs=";
      };
    email = "contact@osbm.dev";
    config = ''
      git.osbm.dev {
        reverse_proxy localhost:3000
      }
    '';
  };

  # now, for the ports of the caddy server
  networking.firewall.allowedTCPPorts = [ 80 443 3000 ];

  networking.hostName = "pochita";
  # log of shame: osbm blamed nix when he wrote "hostname" instead of "hostName"

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.osbm = import ../../home/home.nix {
    inherit config pkgs;
  };

  environment.systemPackages = [];

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services.getty.autologinUser = "osbm";

  # The board and wanted kernel version
  raspberry-pi-nix = {
    board = "bcm2712";
    #kernel-version = "v6_10_12";
  };

  system.stateVersion = "25.05";
}
