{
  description = "Configuration. That's it. Fuck you.";

  inputs = {
	nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
	  system            = "x86_64-linux";
	  pkgs              = import nixpkgs { inherit system; config.allowUnfree = true; };
	  configFiles       = self.outputs.files;
	  configValues      = self.outputs.values;
	  utils             = import ./utils.nix;
	  specialArgs       = {
		inherit inputs;
		inherit configValues;
		inherit configFiles;
	  };
	  # buildHostConfiguration :: hardwareName -> hardwareConfig -> hostname-nixosConfig
	  buildHostConfiguration = utils.buildHostConfiguration {
		configurationFile = configFiles.masterConfig;
		inherit specialArgs;
		inherit home-manager;
		inherit nixpkgs;
	  };
	in {
	  # Holds paths to files which the caller (home-manager config) needs. This
	  # should guarantee that the files exist.
	  files = {
		# These are used in the nushell config text, so we must ensure they
		# exist.
		nushell = {
		  aliases = ./../nushell/aliases.nu;
		  chdir = ./../nushell/chdir.nu;
		  completions = ./../nushell/completions.nu;
		  docker = ./../nushell/docker.nu;
		  external = ./../nushell/external.nu;
		  git = ./../nushell/git.nu;
		  grep = ./../nushell/grep.nu;
		  jj = ./../nushell/jj.nu;
		  kubectl = ./../nushell/kubectl.nu;
		  loadEnv = ./../nushell/load_env.nu;
		  misc = ./../nushell/misc.nu;
		  notes = ./../nushell/notes.org;
		  resiliency = ./../nushell/resiliency.nu;
		  screens = ./../nushell/screens.nu;
		  ssh = ./../nushell/ssh.nu;
		  testsMod = ./../nushell/tests_mod.nu;
		  updatePath = ./../nushell/update_path.nu;
		  vms = ./../nushell/vms.nu ;
		};

		jujutsu = ./../jj/config.toml;
		vim = ./../vim;
		dunst = ./../dunst;
		terminator = ./../terminator;
		masterConfig = ./configuration.nix;
	  };

	  # Holds random values which the caller (home-manager config) needs. These
	  # values are derived somehow from the files in the 'files' set above, so
	  # they must be defined here as well.
	  values = {
		ssh =
		  let
			sshDir = "~/.ssh";
		  in {
			# The identity file used by default and for private github.
			defaultIdentity = "${sshDir}/default";

			# The identity file used at work for contacting Motorola's GitHub or
			# GitLab.
			workIdentity = "${sshDir}/work";
		  };
	  };

	  # Contains information local to specific hosts, i.e., specific machines.
	  hardware = {
		# The qemu virtual machine.
		qemuVm = {
		  hostname = "qemu-william";
		  hardwareConfiguration = ./qemu-hardware-configuration.nix;
		  bootloaderDevice = "/dev/sda";
		};

		# The qemu virtual machine on the work laptop.
		workQemuVm = {
		  hostname = "work-qemu-william";
		  hardwareConfiguration = ./work-qemu-hardware-configuration.nix;
		  bootloaderDevice = "/dev/vda1";
		};

		# Any machine whose hostname we wish to change. Need to build-switch nixos
		# with this, then reboot, and the machine will have a different hostname.
		# Feel free to change [hostname] (the current one) and [hostnameOverride]
		# (the target hostname) to do this. No machine will (or can) use this
		# config long-term.
		hostRename = self.hardware.workQemuVm // {
		  hostname = "mountain-lightning-on-the-net";
		  hostnameOverride = "work-qemu-william";
		};
	  };

	  nixosConfigurations =
		# concatMapAttrs :: (name -> value -> {mapName: mapValue}) -> {name: value} -> {mapName: mapValue}
		#
		# This will produce a set of nixosConfigurations where each attribute is
		# a hostname and contains the hosts's configuration.
		pkgs.lib.attrsets.concatMapAttrs buildHostConfiguration self.outputs.hardware;
	};
}
