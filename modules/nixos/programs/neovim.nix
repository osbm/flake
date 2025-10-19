{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.osbmModules.programs.neovim.enable {
    environment.systemPackages = [
      inputs.osbm-nvim.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };
}
