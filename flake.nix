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
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:osbm/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    osbm-nvim = {
      url = "github:osbm/osbm-nvim";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixvim.follows = "nixvim";
    };
    raspberry-pi-nix = {
      url = "github:nix-community/raspberry-pi-nix";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nix-on-droid,
    deploy-rs,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      tartarus = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/tartarus/configuration.nix];
      };
      ymir = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/ymir/configuration.nix];
      };
      harmonica = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/harmonica/configuration.nix];
      };
      harmonica-sd = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/harmonica-sd/configuration.nix];
      };
      pochita = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/pochita/configuration.nix];
      };
      pochita-sd = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/pochita-sd/configuration.nix];
      };
      myISO = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/iso/configuration.nix
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
        ];
      };
      wallfacer = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/wallfacer/configuration.nix];
      };
    };
    nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
      extraSpecialArgs = {inherit inputs outputs;};
      pkgs = import nixpkgs {system = "aarch64-linux";};
      modules = [./hosts/atreus/configuration.nix];
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.alejandra;
    deploy.nodes.harmonica = {
      hostname = "192.168.0.11";
      profiles.system = {
        user = "osbm";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.harmonica;
      };
    };
  };
}
