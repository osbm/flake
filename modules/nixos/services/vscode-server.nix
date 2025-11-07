{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.osbmModules.services.vscode-server.enable {
      services.code-server = {
        # only true if the machine is not pochita
        enable = config.networking.hostName != "pochita";
        port = 4444;
        disableTelemetry = true;
        disableUpdateCheck = true;
        user = "osbm";
        group = "users";
        # auth = "none";
        host = "${config.networking.hostName}.curl-boga.ts.net";
        hashedPassword = "$argon2i$v=19$m=4096,t=3,p=1$dGc0TStGMDNzSS9JRkJYUFp3d091Q2p0bXlzPQ$zvdE9BkclkJmyFaenzPy2E99SEqsyDMt4IQNZfcfFFQ";
        package = pkgs.vscode-with-extensions.override {
          vscode = pkgs.code-server;
          vscodeExtensions =
            with pkgs.vscode-extensions;
            [
              bbenoist.nix
              catppuccin.catppuccin-vsc
              catppuccin.catppuccin-vsc-icons
              charliermarsh.ruff
              davidanson.vscode-markdownlint
              esbenp.prettier-vscode
              foxundermoon.shell-format
              github.copilot
              github.vscode-github-actions
              github.vscode-pull-request-github
              jnoortheen.nix-ide
              kamadorueda.alejandra
              ms-azuretools.vscode-docker
              ms-python.python
              # ms-vscode-remote.remote-ssh
              timonwong.shellcheck
              tyriar.sort-lines
            ]
            ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
              {
                # Available in nixpkgs, but outdated (0.4.0) at the time of adding
                name = "vscode-tailscale";
                publisher = "tailscale";
                sha256 = "sha256-MKiCZ4Vu+0HS2Kl5+60cWnOtb3udyEriwc+qb/7qgUg=";
                version = "1.0.0";
              }
            ];
        };
      };
      networking.firewall.allowedTCPPorts = [ config.services.code-server.port ];
    };
}
