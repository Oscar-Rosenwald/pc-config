# This file has some utility functions to be used liberally by the rest of the config.
{
  # Builds the nixos flake configuration from the hardware specifications and
  # other dependencies. Should be called on each hardware configuration using
  # nixpkgs.lib.attrsets.concatMapAttrs.
  #
  # - specialArgs: Arguments to pass to each module of the output. Must contain
  #   the flake's inputs. Data from hardwareConfigs will be merged with it.
  #   
  # - home-manager: A home-manager flake instance imported by the caller flake.
  #
  # - configurationFile: The path to the (non-hardware) configuration.nix file.
  #
  # - nixpkgs: The nixpkgs FLAKE (don't import nixpkgs, use the caller flake's
  #   inputs).
  # 
  # - _hardwareName: Ignored name of the hardware configuration. This is passed
  #   by the attrsets.concatMapAttrs function.
  #   
  # - hardwareConfig: Information about the hardware for which we're building
  #   the configuration. Contains:
  #     - The hardware's hostname under [hostname]
  #     - Path to the hardware configuration file under [hardwareConfiguration]
  buildHostConfiguration = 
    { 
      specialArgs,
      home-manager,
      nixpkgs,
      configurationFile,
    }: _hardwareName: hardwareConfig:
	let
	  hostname = hardwareConfig.hostname;
	  hardwareConfigurationFile = hardwareConfig.hardwareConfiguration;
	  homeManagerConfig = {
		home-manager.useGlobalPkgs = true;
		home-manager.useUserPackages = true;
		home-manager.backupFileExtension = ".backup";
		home-manager.extraSpecialArgs =  specialArgs; # Need to pass specialArgs to this inline module.
		home-manager.users.william = import ./home.nix;
	  };
	in {
	  # This procudes a set whose attribute has the name of the hardware hostname.
	  # Flakes' nixosConfigurations is a set where each attribute is a hostname,
	  # so we construct that here and merge the sets by the caller function.
	  ${hostname} = nixpkgs.lib.nixosSystem {
		specialArgs = specialArgs // {
		  inherit hostname;
		  inherit hardwareConfigurationFile;
		};
			  
		modules = [
		  configurationFile
		  home-manager.nixosModules.home-manager
		  homeManagerConfig
		];
	  };
	};
}
