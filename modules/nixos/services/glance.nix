{
  lib,
  config,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.glance.enable {
      services.glance = {
        enable = true;
        openFirewall = true;
        settings = {
          server = {
            port = 3838;
            host = "0.0.0.0";
          };
          branding = {
            # stolen from notohh/snowflake but i love it so much
            custom-footer = ''<b><p>ᓚᘏᗢ</p></b>'';
          };
          pages = [
            {
              columns = [
                {
                  size = "small";
                  widgets = [
                    { type = "calendar"; }
                    {
                      type = "bookmarks";
                      groups = [
                        {
                          title = "My Profiles";
                          same-tab = true;
                          color = "200 50 50";
                          links = [
                            {
                              title = "GitHub";
                              url = "https://github.com/osbm";
                            }
                            {
                              title = "Gitlab";
                              url = "https://gitlab.com/osbm";
                            }
                            {
                              title = "Crates.io";
                              url = "https://crates.io/users/osbm";
                            }
                            {
                              title = "HuggingFace";
                              url = "https://huggingface.co/osbm";
                            }
                            {
                              title = "Bluesky";
                              url = "https://bsky.app/profile/osbm.dev";
                            }
                            {
                              title = "Docker Hub";
                              url = "https://hub.docker.com/u/osbm";
                            }
                            {
                              title = "Kaggle";
                              url = "https://www.kaggle.com/osmanf";
                            }
                          ];
                        }
                        {
                          title = "Documents";
                          links = [
                            {
                              title = "Nixos Search";
                              url = "https://search.nixos.org";
                            }
                          ];
                        }
                      ];
                    }
                  ];
                }

                {
                  size = "full";
                  widgets = [
                    {
                      type = "search";
                      search-engine = "google";
                      bangs = [
                        {
                          title = "youtube";
                          shortcut = "!yt";
                          url = "https://www.youtube.com/results?search_query={QUERY}";
                        }
                        {
                          title = "nixpkgs";
                          shortcut = "!np";
                          url = "https://search.nixos.org/packages?channel=unstable&query={QUERY}";
                        }
                        {
                          title = "nixos";
                          shortcut = "!no";
                          url = "https://search.nixos.org/options?channel=unstable&query={QUERY}";
                        }
                      ];
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
                          icon = "sh:nixos";
                          title = "Attix Binary Cache";
                          url = "https://cache.osbm.dev";
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
                        {
                          icon = "si:json";
                          title = "Wanikani Stats";
                          url = "http://pochita:8501";
                        }
                      ];
                      title = "Services";
                      type = "monitor";
                    }
                  ];
                }
              ];
              name = "Home";
              content = "Welcome to osbm's home page!";
            }
          ];
        };
      };
      networking.firewall.allowedTCPPorts = [ config.services.glance.settings.server.port ];
    })
    (lib.mkIf
      (config.osbmModules.services.cloudflared.enable && config.osbmModules.services.glance.enable)
      {
        services.cloudflared.tunnels = {
          "91b13f9b-81be-46e1-bca0-db2640bf2d0a" = {
            default = "http_status:404";
            credentialsFile = "/home/osbm/.cloudflared/91b13f9b-81be-46e1-bca0-db2640bf2d0a.json";
            ingress = {
              "home.osbm.dev" = {
                service = "http://localhost:${toString config.services.glance.settings.server.port}";
              };
            };
          };
        };
      }
    )

    # if nginx and glance are both enabled, set up a reverse proxy
    (lib.mkIf
      (config.osbmModules.services.nginx.enable && config.osbmModules.services.glance.enable)
      {
        services.nginx.virtualHosts."home.osbm.dev" = {
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.glance.settings.server.port}";
          };
        };
      }
    )
  ];
}
