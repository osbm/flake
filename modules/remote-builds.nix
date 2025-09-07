{
   config,
   outputs,
   lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf (config.networking.hostName == "pochita") {
      nix.distributedBuilds = true;
      # nix.settings.builders-use-substitutes = true;
      nix.buildMachines = [
        {
          hostName = "ymir";
          systems = ["x86_64-linux" "aarch64-linux"];
          supportedFeatures = outputs.nixosConfigurations.ymir.config.nix.settings.system-features;
          sshKey = config.age.secrets.ssh-key-private.path;
          sshUser = "osbm";
          protocol = "ssh-ng";
        }
        {
          hostName = "wallfacer";
          systems = ["x86_64-linux"];
          supportedFeatures = outputs.nixosConfigurations.wallfacer.config.nix.settings.system-features;
          sshKey = config.age.secrets.ssh-key-private.path;
          sshUser = "osbm";
          protocol = "ssh-ng";
        }
      ];
    })
  ];
}
