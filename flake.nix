{
  description = "My system configuration";
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
      deploy-rs,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      makePkgs = system: import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        tartarus = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/tartarus/configuration.nix ];
        };
        ymir = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/ymir/configuration.nix ];
        };
        harmonica = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/harmonica/configuration.nix ];
        };
        harmonica-sd = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/harmonica-sd/configuration.nix ];
        };
        pochita = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/pochita/configuration.nix ];
        };
        pochita-sd = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/pochita-sd/configuration.nix ];
        };
        myISO = nixpkgs.lib.nixosSystem {
          modules = [
            ./hosts/iso/configuration.nix
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
          ];
        };
        wallfacer = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/wallfacer/configuration.nix ];
        };
      };
      nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
        extraSpecialArgs = { inherit inputs outputs; };
        pkgs = import nixpkgs { system = "aarch64-linux"; };
        modules = [ ./hosts/atreus/configuration.nix ];
      };

      lib = import ./lib { inherit (nixpkgs) lib; };
      formatter = forAllSystems (system: (makePkgs system).nixfmt-rfc-style);
      deploy.nodes.harmonica = {
        hostname = "192.168.0.11";
        profiles.system = {
          user = "osbm";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.harmonica;
        };
      };
    };
}
