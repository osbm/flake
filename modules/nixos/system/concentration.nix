{ lib, config, ... }:
let
  cfg = config.osbmModules.concentration;
  
  blockedSites = lib.flatten [
    (lib.optional cfg.blockYoutube [
      "youtube.com"
      "www.youtube.com"
      "m.youtube.com"
      "youtu.be"
    ])
    (lib.optional cfg.blockTwitter [
      "twitter.com"
      "www.twitter.com"
      "x.com"
      "www.x.com"
      "mobile.twitter.com"
      "mobile.x.com"
    ])
    (lib.optional cfg.blockBluesky [
      "bsky.app"
      "www.bsky.app"
      "bluesky.app"
      "www.bluesky.app"
    ])
  ];
  
  hostsEntries = lib.concatMapStrings (site: "127.0.0.1 ${site}\n") blockedSites;
in
{
  config = lib.mkIf (blockedSites != []) {
    networking.extraHosts = hostsEntries;
  };
}
