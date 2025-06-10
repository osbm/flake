{
  lib,
  config,
  ...
}: {
  options.enableFirefox = lib.mkEnableOption "enableFirefox";
  config = {
    programs.firefox = {
      enable = config.enableFirefox;
      languagePacks = [
        "ja"
        "tr"
        "en-US"
      ];
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        # DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableAccounts = true;
        DisableFirefoxScreenshots = true;
        StartPage = "previous-session";
        # OverrideFirstRunPage = "";
        # OverridePostUpdatePage = "";
        # DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "always"; # alternatives: "never" or "newtab"
        # DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
        # SearchBar = "unified"; # alternat
        ExtensionSettings = with builtins; let
          extension = shortId: uuid: {
            name = uuid;
            value = {
              install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
              installation_mode = "normal_installed";
            };
          };
        in
          listToAttrs [
            (extension "tree-style-tab" "treestyletab@piro.sakura.ne.jp")
            (extension "ublock-origin" "uBlock0@raymondhill.net")
            (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
            (extension "motivation-new-tab" "")
            (extension "return-youtube-dislikes" "{762f9885-5a13-4abd-9c77-433dcd38b8fd}")
            (extension "violentmonkey" "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}")
            (extension "vimium-ff" "{d7742d87-e61d-4b78-b8a1-b469842139fa}")
            # (extension "tabliss" "extension@tabliss.io")
            # (extension "umatrix" "uMatrix@raymondhill.net")
            # (extension "libredirect" "7esoorv3@alefvanoon.anonaddy.me")
            (extension "clearurls" "{74145f27-f039-47ce-a470-a662b129930a}")
          ];
        # To add additional extensions, find it on addons.mozilla.org, find
        # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
        # Then, download the XPI by filling it in to the install_url template, unzip it,
        # run `jq .browser_specific_settings.gecko.id manifest.json` or
        # `jq .applications.gecko.id manifest.json` to get the UUID
      };
      profiles.default = {
        id = 0;
        name = "osbm";

        userChrome = ''
          #tabbrowser-tabs {
            visibility: collapse;
          }
        '';
        settings = {
          # "Open previous windows and tabs"
          "browser.startup.page" = 3;
          "browser.contentblocking.category" = true;
          "extensions.pocket.enabled" = false;
          "extensions.screenshots.disabled" = true;
          "browser.topsites.contile.enabled" = false;
          "browser.formfill.enable" = false;
          "browser.search.suggest.enabled" = false;
          "browser.search.suggest.enabled.private" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "ui.key.menuAccessKeyFocuses" = false;
        };
      };
    };
  };
}
