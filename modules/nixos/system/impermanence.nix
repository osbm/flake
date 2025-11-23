# impermanence
{
  lib,
  inputs,
  config,
  ...
}:
let
  # Build list of regular users based on defaultUser and familyUser options
  regularUsers = [
    config.osbmModules.defaultUser
  ]
  ++ lib.optional config.osbmModules.familyUser.enable "bayram";

  # Generate user persistence configuration
  userPersistence = lib.genAttrs regularUsers (_username: {
    directories = [
      "Documents"
      {
        directory = ".gnupg";
        mode = "0700";
      }
      {
        directory = ".ssh";
        mode = "0700";
      }
      ".local/share/direnv"
    ];
    # files = [
    #   ".screenrc"
    # ];
  });
in
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  config = lib.mkMerge [
    # Enable impermanence root if configured
    (lib.mkIf config.osbmModules.hardware.disko.zfs.root.impermanenceRoot {
      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          # systemd and other machine logs
          "/var/log"

          # information about nixos users and groups
          "/var/lib/nixos"

          # systemd coredumps to debug crashes
          "/var/lib/systemd/coredump"

          # NetworkManager connection profiles and WiFi passwords
          "/etc/NetworkManager/system-connections"

        ];
        files = [
          # the fuck is this file
          # "/etc/machine-id"

          # user passwords
          # "/etc/shadow"
          # fuck me if i move the shadow file to the persist folder,
          # i cant use sudo command to rebuild my system
        ];
        users = userPersistence;
      };
    })
  ];
}
