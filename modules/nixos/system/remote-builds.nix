{ lib, config, ... }:
{
  config = lib.mkIf config.osbmModules.remoteBuild.enable {
    # Remote build configuration
    # This should be customized per-host
    nix.buildMachines = lib.mkDefault [];
    nix.distributedBuilds = lib.mkDefault true;
  };
}
