{ pkgs, ... }:
{

  importList = lib.mapAttrsToList (name: _path: ./. + "/${name}") (
    lib.filterAttrs (
      filename: kind: filename != "default.nix" && (kind == "regular" || kind == "directory")
    ) (builtins.readDir ./.)
  );
}
