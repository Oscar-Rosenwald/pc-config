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
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      configFiles = inputs.myConfigDir.nixosModules.files;
      configValues = inputs.myConfigDir.nixosModules.values;
      specialArgs = {
		inherit inputs;
		inherit configValues;
		inherit configFiles;
	  };

      homeManagerDefaults = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = ".backup";

		# Need to pass specialArgs to this inline module.
        home-manager.extraSpecialArgs =  specialArgs;
        home-manager.users.william = import ./home.nix;
      };
    in {
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
        specialArgs = specialArgs // {
          hardwareConfiguration = configFiles.nix.qemuHardwareConfiguration;
        };

        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          homeManagerDefaults
        ];
      };
    };
}
