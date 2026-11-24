{
  config,
  lib,
  pkgs,
  ...
}:
let
  # ttyd's page asks for these fonts (fontFamily in services/ttyd.nix); serve
  # them so phones etc. render text + yazi/eza icons without installing anything.
  termFonts = pkgs.runCommand "term-webfonts" { } ''
    mkdir $out
    for f in FiraCodeNerdFontMono-Regular.ttf FiraCodeNerdFontMono-Bold.ttf; do
      cp "$(find ${pkgs.nerd-fonts.fira-code} -name $f | head -n1)" $out/$f
    done
    # symbols missing from FiraCode (claude code's ⏵ ⏺ ✻ etc.)
    cp "$(find ${pkgs.noto-fonts} -name NotoSansSymbols2-Regular.ttf | head -n1)" $out/
  '';
  fontCss = lib.concatStrings [
    ''<link rel="preload" href="/_fonts/FiraCodeNerdFontMono-Regular.ttf" as="font" type="font/ttf" crossorigin>''
    "<style>"
    ''@font-face{font-family:"FiraCode Nerd Font Mono";src:url(/_fonts/FiraCodeNerdFontMono-Regular.ttf) format("truetype");font-weight:400}''
    ''@font-face{font-family:"FiraCode Nerd Font Mono";src:url(/_fonts/FiraCodeNerdFontMono-Bold.ttf) format("truetype");font-weight:700}''
    ''@font-face{font-family:"Noto Sans Symbols 2";src:url(/_fonts/NotoSansSymbols2-Regular.ttf) format("truetype")}''
    "</style>"
    # xterm measures cells before the webfont arrives and keeps the fallback
    # metrics until reload; once fonts load, bounce fontFamily so ttyd's
    # window.term re-measures and refits. (double quotes only; no single quotes, backslashes or $:
    # it sits inside an nginx sub_filter string)
    "<script>"
    "(()=>{const fix=()=>{const t=window.term;if(!t)return;"
    "const f=t.options.fontFamily;t.options.fontFamily=\"monospace\";"
    "t.options.fontFamily=f;t.fit&&t.fit()};"
    "document.fonts.addEventListener(\"loadingdone\",fix);"
    "document.fonts.load(\"14px FiraCode Nerd Font Mono\").then(()=>{"
    "let n=0;const w=()=>window.term?fix():n++<50&&setTimeout(w,100);w()})})()"
    "</script>"
  ];
in
{
  config = lib.mkMerge [
    (lib.mkIf config.osbmModules.services.nginx.enable {
      services.nginx = {
        enable = true;

        # TEMP: NGINX2Root (CVE-2026-123007 et al.), fixed in 1.30.7 which is on
        # nixpkgs master (f0a5d452ddf1) but not yet nixos-unstable. Remove once
        # the pinned nixpkgs ships 1.30.7 — the assert below fails loudly then.
        package =
          assert lib.assertMsg (pkgs.nginxStable.version == "1.30.6")
            "nixpkgs nginxStable is now ${pkgs.nginxStable.version}: remove the TEMP NGINX2Root override in modules/nixos/services/nginx.nix";
          pkgs.nginxStable.overrideAttrs (_: rec {
            version = "1.30.7";
            src = pkgs.fetchurl {
              url = "https://nginx.org/download/nginx-${version}.tar.gz";
              hash = "sha256-JWW1yDcFDpWPcPsPc8SOK8pFQq00n9NW9G+wxyYQvG4=";
            };
          });

        # Catch-all default server: return 404 for unknown subdomains
        virtualHosts."_" = {
          default = true;
          useACMEHost = "osbm.dev";
          forceSSL = true;
          locations."/".return = "444";
        };

        virtualHosts."grafana.osbm.dev" = {
          useACMEHost = "osbm.dev";
          forceSSL = true;
          locations."/" = {
            proxyWebsockets = true;
            extraConfig = ''
              resolver 100.100.100.100;
              set $grafana http://pochita.curl-boga.ts.net:3000;
              proxy_pass $grafana;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };

        # Open WebUI runs on ymir (the GPU box, next to ollama); same
        # cross-tailnet hop as grafana above. tailnet-only like hledger:
        # auth is disabled in the container, so the public IP must never
        # reach it even with a matching SNI
        virtualHosts."openwebui.osbm.dev" = {
          useACMEHost = "osbm.dev";
          forceSSL = true;
          locations."/" = {
            proxyWebsockets = true;
            extraConfig = ''
              allow 100.64.0.0/10;
              allow fd7a:115c:a1e0::/48;
              deny all;

              resolver 100.100.100.100;
              set $openwebui http://ymir.curl-boga.ts.net:7070;
              proxy_pass $openwebui;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              # document/image uploads and slow streamed completions
              client_max_body_size 0;
              proxy_buffering off;
              proxy_read_timeout 600s;
            '';
          };
        };

        # nix binary cache, atticd runs on pochita. access control is atticd's
        # job (private cache + tokens), nginx only forwards.
        virtualHosts."attic-pochita.osbm.dev" = {
          useACMEHost = "osbm.dev";
          forceSSL = true;
          locations."/" = {
            extraConfig = ''
              resolver 100.100.100.100;
              set $attic http://pochita.curl-boga.ts.net:7080;
              proxy_pass $attic;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              # NAR uploads are big and slow: no size cap, stream them through
              # instead of spooling to apollo's disk first
              client_max_body_size 0;
              proxy_request_buffering off;
              proxy_buffering off;
              proxy_http_version 1.1;
              proxy_read_timeout 600s;
              proxy_send_timeout 600s;
            '';
          };
        };

        # Route [name].sync.osbm.dev -> [name].curl-boga.ts.net:8384
        appendHttpConfig = ''
          server {
            listen 80;
            listen 443 ssl;
            server_name ~^(?<device>.+)\.sync\.osbm\.dev$;

            ssl_certificate /var/lib/acme/sync.osbm.dev/fullchain.pem;
            ssl_certificate_key /var/lib/acme/sync.osbm.dev/key.pem;

            resolver 100.100.100.100;

            location / {
              set $backend http://$device.curl-boga.ts.net:8384;
              proxy_pass $backend;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            }
          }

          server {
            listen 443 ssl;
            server_name ~^(?<device>.+)\.(?<svc>term|vnc)\.osbm\.dev$;

            ssl_certificate /var/lib/acme/term.osbm.dev/fullchain.pem;
            ssl_certificate_key /var/lib/acme/term.osbm.dev/key.pem;

            allow 100.64.0.0/10;
            allow fd7a:115c:a1e0::/48;
            deny all;

            resolver 100.100.100.100;

            set $port 7681;
            if ($svc = vnc) {
              set $port 6080;
            }

            location / {
              set $backend http://$device.curl-boga.ts.net:$port;
              proxy_pass $backend;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_read_timeout 1d;
              proxy_send_timeout 1d;
              proxy_buffering off;
              # inject the webfont into ttyd's page (needs uncompressed upstream)
              proxy_set_header Accept-Encoding "";
              sub_filter '</head>' '${fontCss}</head>';
            }

            location /_fonts/ {
              alias ${termFonts}/;
              add_header Cache-Control "public, max-age=31536000, immutable";
            }
          }
        '';
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];

      systemd.services.nginx = {
        wants = [
          "acme-sync.osbm.dev.service"
          "acme-term.osbm.dev.service"
        ];
        after = [
          "acme-sync.osbm.dev.service"
          "acme-term.osbm.dev.service"
        ];
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "osbm@osbm.dev";
        defaults.dnsResolver = "1.1.1.1:53";
        certs."sync.osbm.dev" = {
          reloadServices = [ "nginx.service" ];
          domain = "*.sync.osbm.dev";
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          credentialFiles = {
            "CF_DNS_API_TOKEN_FILE" = config.age.secrets.cloudflare-apollo-zone-dns-edit.path;
          };
          group = "nginx";
        };
        certs."term.osbm.dev" = {
          reloadServices = [ "nginx.service" ];
          domain = "*.term.osbm.dev";
          extraDomainNames = [ "*.vnc.osbm.dev" ];
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          credentialFiles = {
            "CF_DNS_API_TOKEN_FILE" = config.age.secrets.cloudflare-apollo-zone-dns-edit.path;
          };
          group = "nginx";
        };
        certs."osbm.dev" = {
          domain = "*.osbm.dev";
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          credentialFiles = {
            "CF_DNS_API_TOKEN_FILE" = config.age.secrets.cloudflare-apollo-zone-dns-edit.path;
          };
          group = "nginx";
        };
      };
    })

    (lib.mkIf
      (
        config.osbmModules.services.nginx.enable
        && config.osbmModules.hardware.disko.zfs.root.impermanenceRoot
      )
      {
        # environment.persistence."/persist" = {
        #   directories = [
        #     {
        #       directory = "/var/lib/acme";
        #       user = "acme";
        #       group = "nginx";
        #       mode = "0750";
        #     }
        #   ];
        # };
      }
    )
  ];
}
