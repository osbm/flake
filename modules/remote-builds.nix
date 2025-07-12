{
  #  config,
  #  outputs,
  ...
}:
{
  # nix.distributedBuilds = true;
  # nix.settings.builders-use-substitutes = true;
  # nix.buildMachines = [
  #  {
  #   hostName = "ymir.curl-boga.ts.net";
  #    systems = ["x86_64-linux" "aarch64-linux"];
  #    supportedFeatures = outputs.nixosConfigurations.ymir.config.nix.settings.system-features;
  #    sshKey = config.age.secrets.ssh-key-private.path;
  #    sshUser = "osbm";
  #    protocol = "ssh-ng";
  #  }
  # ];
}
