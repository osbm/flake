{
  lib,
  config,
  ...
}:
{
  options = {
    myModules.enableGlance = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Glance server";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.myModules.enableGlance {
  services.glance = {
    enable = true;
    openFirewall = true;
    settings = {
      server = {
        port = 3838;
        host = "0.0.0.0";
      };
      pages = [
        {
          columns = [
            {
              size = "small";
              widgets = [
                {type = "calendar";}
                {
                  type = "repository";
                  repository = "NixOS/nixpkgs";
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "repository";
                  repository = "NixOS/nixpkgs";
                }
                {
                  cache = "1m";
                  sites = [
                    {
                      icon = "sh:forgejo";
                      title = "Forgejo git server";
                      url = "https://git.osbm.dev";
                    }
                    {
                      icon = "si:ollama";
                      title = "Open Webui";
                      url = "http://ymir.curl-boga.ts.net:7070/";
                    }
                    {
                      icon = "sh:jellyfin";
                      title = "Jellyfin";
                      url = "http://ymir.curl-boga.ts.net:8096/";
                    }
                    {
                      icon = "sh:nixos";
                      title = "Hydra";
                      url = "http://wallfacer.curl-boga.ts.net:3000";
                    }
                    {
                      icon = "sh:visual-studio-code";
                      title = "Ymir Remote VSCode";
                      url = "http://ymir.curl-boga.ts.net:4444/";
                    }
                    {
                      icon = "sh:visual-studio-code";
                      title = "Tartarus Remote VSCode";
                      url = "http://tartarus.curl-boga.ts.net:4444/";
                    }
                    {
                      icon = "sh:visual-studio-code";
                      title = "Wallfacer Remote VSCode";
                      url = "http://wallfacer.curl-boga.ts.net:4444/";
                    }
                  ];
                  title = "Services";
                  type = "monitor";
                }
              ];
            }
          ];
          name = "Home";
          content = "Welcome to Pochita's home page!";
        }
      ];
    };
  };
      networking.firewall.allowedTCPPorts = [ config.services.glance.port ];
      services.cloudflared.tunnels = {
        "91b13f9b-81be-46e1-bca0-db2640bf2d0a" = {
          default = "http_status:404";
          credentialsFile = "/home/osbm/.cloudflared/91b13f9b-81be-46e1-bca0-db2640bf2d0a.json";
          ingress = {
            "home.osbm.dev" = {
              service = "http://localhost:3838";
            };
          };
        };
      };
    })
  ];
}
