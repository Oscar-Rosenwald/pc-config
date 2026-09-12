{
  description = "Core Computer Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
	privateDir = builtins.fetchurl "TODO - URL to master of Private";
	home-manager = {
	  url = "github:nix-community/home-manager/release-26.05";
	  inputs.nixpkgs.follows = "nixpkgs";
	};

	# For other things to pass to the output modules, do something like this:
	# 
	#   helix.url = "github:helix-editor/helix/master";
	#
	# Then in outputs.nixosConfiguration.<name>, on the same level as modules,
	# add this:
	#
	#   specialArgs = { inherit inputs; };
	#
	# This will make the package "helix" available in configuration.nix under
	# an argument called "inputs" like: inputs.helix. ...
	#
	# The content of specialArgs will be passed to all output modules.
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
	let
	  system = "x86_64-linux";
	  pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
	in {
	  nixosConfigurations."will's thin thing" = nixpkgs.lib.nixosSystem {
		specialArgs = { inherit inputs; };
		modules = [
		  ./configuration.nix

		  # Since we're importing home-manager as a dependency, we cannot
		  # include it here as a file (the file doesn't exit).
		  #
		  # home-manager has a nixosModules attribute in its flake.nix:
		  #
		  #   nixosModules = rec {
          #     home-manager = ./nixos;
		  #     default = home-manager;
		  #   };
		  #
		  # So we're importing home-manager.nixosModules.home-manager
		  home-manager.nixosModules.home-manager
		  { # This is an inline module, not a function argumet.
			home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
			home-manager.users.william = import ./home.nix;
		  }

		];
	  };
	};
}