{ inputs, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos
    inputs.jovian-nixos.nixosModules.default
  ];

  osbmModules = {
    desktopEnvironment = {
      plasma.enable = true;
    };
    familyUser.enable = true;
    programs = {
      steam.enable = true;
    };
    services.syncthing.enable = true;
    fonts.enable = true;
    hardware = {
      # hibernation.enable = false;
      sound.enable = true;
    };
    i18n.enable = true;
  };

  jovian = {
    devices.steamdeck = {
      enable = true;
      autoUpdate = true;
    };
    steam = {
      enable = true;
      autoStart = true;
      user = "osbm";
      desktopSession = "plasma";
    };
    decky-loader.enable = true;
  };

  # Jovian's decky-loader still builds its frontend with pnpm 9, which nixpkgs
  # marks insecure. Build-time only; drop this once upstream moves to pnpm 10.
  nixpkgs.config.permittedInsecurePackages = [ "pnpm-9.15.9" ];

  # Tripwires so the exception above can't silently outlive its reason.
  assertions = [
    {
      # 69b45849 (2026-07 bump): decky-loader still pnpm_9, exception still needed
      assertion = inputs.jovian-nixos.rev == "69b458491084c117e6db8761aa52597e67446296";
      message = "jovian-nixos was updated: check whether decky-loader still builds with pnpm 9. If not, remove the permittedInsecurePackages entry and these assertions; otherwise bump the pinned rev here.";
    }
    {
      assertion = pkgs.pnpm_9.meta.knownVulnerabilities or [ ] != [ ];
      message = "pnpm_9 is no longer marked insecure: remove the pnpm-9.15.9 permittedInsecurePackages entry and these assertions.";
    }
  ];

  # Steam Deck UI (CEF) ignores fontconfig and only reads real font files from
  # ~/.local/share/fonts and /usr/share/fonts, so system fonts render as tofu
  # boxes. Populate the X11 font dir and symlink it into the user's home.
  # See: https://github.com/Jovian-Experiments/Jovian-NixOS/issues/355
  fonts.fontDir.enable = true;

  system.userActivationScripts.linkSteamFonts.text = ''
    if [[ ! -h "$HOME/.local/share/fonts" ]]; then
      mkdir -p "$HOME/.local/share"
      ln -s /run/current-system/sw/share/X11/fonts "$HOME/.local/share/fonts"
    fi
  '';

  networking = {
    hostName = "ares";

    firewall.allowedTCPPorts = [
      8889
      8000
    ];

    networkmanager.enable = true;
  };

  system.stateVersion = "26.05"; # changing this is a great taboo of the nixos world
}
