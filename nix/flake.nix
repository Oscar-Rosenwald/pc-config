{
  description = "Core Computer Configuration";

  inputs = {
	nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
	myConfigDir.url = "github:Oscar-Rosenwald/pc-config/master";
	home-manager = {
	  url = "github:nix-community/home-manager/release-26.05";
	  inputs.nixpkgs.follows = "nixpkgs";
	};

	# For other things to pass to the output modules, do something like this:
	# 
	#   helix.url = "github:helix-editor/helix/master";
	#
	# (Add helix.flake = false if it's just a repo with no flake.nix) Then in
	# outputs.nixosConfiguration.<name>, on the same level as 'modules,' add this:
	#
	#   specialArgs = { inherit inputs; };
	#
	# This will make the package "helix" available in configuration.nix under an
	# argument called "inputs" like: inputs.helix. If this doesn't work (I've
	# not been able to figure out why this is), use "specialArgs" instead of
	# "inputs" in the target module. I really don't get why it's inputs
	# sometimes and not other times.
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
	let
	  system			= "x86_64-linux";
	  pkgs				= import nixpkgs { inherit system; config.allowUnfree = true; };
	  customConfig		= inputs.myConfigDir.nixosModules;
	  configFiles		= customConfig.files;
	  configValues		= customConfig.values;
	  hardwareConfigs	= customConfig.hardware;
	  configUtils		= customConfig.utils;
	  specialArgs		= {
		inherit inputs;
		inherit configValues;
		inherit configFiles;
	  };
          # :: hardwareName -> hardwareConfig -> hostname-nixosConfig
          buildHostConfiguration = configUtils.buildHostConfiguration {
            inherit specialArgs;
            inherit home-manager;
            inherit nixpkgs;
            configurationFile = ./configuration.nix;
          };
	in {
          nixosConfigurations = 
		# Takes the set hardwareConfig, and calls the function below on each of
		# its attributes. The result is a list of sets, which are merged. This
		# will produce a set of nixosConfigurations where each attribute is a
		# hostname and contains the hosts's configuration.
		pkgs.lib.attrsets.concatMapAttrs buildHostConfiguration hardwareConfigs;
	};
}
