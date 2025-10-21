# impermanence 
{lib, inputs, config, ...}:
let
  # Filter out 'root' from the users list since it's a special system user
  regularUsers = builtins.filter (u: u != "root") config.osbmModules.users;
  
  # Generate user persistence configuration
  userPersistence = lib.genAttrs regularUsers (username: {
    directories = [
      "Documents"
      { directory = ".gnupg"; mode = "0700"; }
      { directory = ".ssh"; mode = "0700"; }
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
    (lib.mkIf (config.osbmModules.hardware.disko.zfs.root.impermanenceRoot) {
      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/etc/NetworkManager/system-connections"
        ];
        files = [
          "/etc/machine-id"
        ];
        users = userPersistence;
      };
    })
  ];
}