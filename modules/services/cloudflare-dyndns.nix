{
  lib,
  config,
  pkgs,
  ...
}:
let
  # https://github.com/NixOS/nixpkgs/pull/394352
  cloudflare-dyndns-5-3 = pkgs.cloudflare-dyndns.overrideAttrs rec {
    version = lib.warnIfNot (pkgs.cloudflare-dyndns.version == "5.0") "The cloudflare-dyndns package is updated, you should remove this override" "5.3";
    src = pkgs.fetchFromGitHub {
      owner = "kissgyorgy";
      repo = "cloudflare-dyndns";
      rev = "v${version}";
      hash = "sha256-t0MqH9lDfl+cAnPYSG7P32OGO8Qpo1ep0Hj3Xl76lhU=";
    };
    build-system = with pkgs.python3Packages; [
      hatchling
    ];
    dependencies = with pkgs.python3Packages; [
      click
      httpx
      pydantic
      truststore
    ];
  };
in
{
  options = {
    myModules.enableCloudflareDyndns = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable a service to push my public IP address to my Cloudflare domain.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableCloudflareDyndns {
      services.cloudflare-dyndns = {
        package = cloudflare-dyndns-5-3;
        enable = true;
        apiTokenFile = "/persist/cloudflare-dyndns";
        proxied = true;
        domains = [
          "git.osbm.dev"
          "aifred.osbm.dev"
        ];
      };
    })
  ];
}
