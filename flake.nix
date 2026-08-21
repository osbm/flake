{
  description = "My system configuration";
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      # "http://wallfacer.curl-boga.ts.net:7080/main"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # "main:2AjPdIsbKyoTGuw+4x2ZXMUT/353CXosW9pdbTQtjqw="
    ];
  };

  inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # x86_64-darwin was dropped from unstable (26.11); 26.05 is the last release
    # supporting it, with security fixes until end of 2026. Only prometheus uses it.
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    osbm-nvim.url = "github:osbm/osbm-nvim";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    raspberry-pi-nix = {
      url = "github:nix-community/raspberry-pi-nix";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # last revision whose weekly index still includes x86_64-darwin (dropped upstream 2026-07-12)
    nix-index-database-darwin = {
      url = "github:nix-community/nix-index-database/fab14c7b63499d57cb6673d5690168c3ec42b99a";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    mobile-nixos = {
      url = "github:mobile-nixos/mobile-nixos";
      flake = false;
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-on-droid,
      nix-darwin,
      treefmt-nix,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems f;
      # unstable no longer evaluates for x86_64-darwin
      makePkgs =
        system:
        import (if system == "x86_64-darwin" then inputs.nixpkgs-darwin else nixpkgs) { inherit system; };
      makeNixosConfig =
        configName:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/nixos/${configName}/configuration.nix ];
        };
      nixosConfigNames = builtins.attrNames (builtins.readDir ./hosts/nixos);
      makeNixOnDroidConfig =
        configName:
        nix-on-droid.lib.nixOnDroidConfiguration {
          extraSpecialArgs = { inherit inputs outputs; };
          pkgs = import nixpkgs { system = "aarch64-linux"; };
          modules = [ ./hosts/nixOnDroidHosts/${configName}/configuration.nix ];
        };
      nixOnDroidConfigNames = builtins.attrNames (builtins.readDir ./hosts/nixOnDroidHosts);
      treefmtEval = forAllSystems (system: treefmt-nix.lib.evalModule (makePkgs system) ./treefmt.nix);
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs nixosConfigNames makeNixosConfig;
      nixOnDroidConfigurations = nixpkgs.lib.genAttrs nixOnDroidConfigNames makeNixOnDroidConfig;
      darwinConfigurations.prometheus = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [ ./hosts/darwinHosts/prometheus/configuration.nix ];
        specialArgs = { inherit inputs outputs; };
      };
      lib = import ./lib { inherit (nixpkgs) lib; };
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);
      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      nixosModules.default = ./modules/nixos;
      homeManagerModules.default = ./modules/home-manager;
    };
}
