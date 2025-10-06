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
    minegrub-theme = {
      url = "github:Lxtharia/minegrub-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    osbm-nvim.url = "github:osbm/osbm-nvim";
    raspberry-pi-nix = {
      url = "github:nix-community/raspberry-pi-nix";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-on-droid,
      nix-darwin,
      deploy-rs,
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
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      makePkgs = system: import nixpkgs { inherit system; };
      makeNixosConfig =
        configName:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/${configName}/configuration.nix ];
        };
      configNames = builtins.attrNames (builtins.readDir ./hosts);
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs configNames (name: makeNixosConfig name);
      nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
        extraSpecialArgs = { inherit inputs outputs; };
        pkgs = import nixpkgs { system = "aarch64-linux"; };
        modules = [ ./nixOnDroidHosts/atreus/configuration.nix ];
      };
      darwinConfigurations.prometheus = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [ ./darwinHosts/prometheus/configuration.nix ];
        specialArgs = { inherit inputs outputs; };
      };
      lib = import ./lib { inherit (nixpkgs) lib; };
      formatter = forAllSystems (system: (makePkgs system).nixfmt-tree);
      deploy.nodes.harmonica = {
        hostname = "192.168.0.11";
        profiles.system = {
          user = "osbm";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.harmonica;
        };
      };
      packages = forAllSystems (
        system:
        let
          makeNixosConfigWithSystemOverride =
            configName:
            nixpkgs.lib.nixosSystem {
              specialArgs = { inherit inputs outputs; };
              modules = [
                ./hosts/${configName}/configuration.nix
                { nixpkgs.hostPlatform = nixpkgs.lib.mkForce system; }
              ];
            };
          dotfilesMachineNames = [
            "ymir"
            "pochita"
            "tartarus"
            "wallfacer"
          ];
        in
        builtins.listToAttrs (
          map (name: {
            name = "${name}-dotfiles";
            value = (makeNixosConfigWithSystemOverride name).config.home-manager.users.osbm.home-files;
          }) dotfilesMachineNames
        )
      );
    };
}
