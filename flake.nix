{
  description = "Config files. That's it. Fuck you.";

  inputs = { };

  outputs = { ... }@inputs: {
	# Holds paths to files which the caller (home-manager config) needs. This
	# should guarantee that the files exist.
	files = {
	  # These are used in the nushell config text, so we must ensure they
	  # exist.
	  nushell = {
		aliases = ./nushell/aliases.nu;
		chdir = ./nushell/chdir.nu;
		completions = ./nushell/completions.nu;
		docker = ./nushell/docker.nu;
		external = ./nushell/external.nu;
		git = ./nushell/git.nu;
		grep = ./nushell/grep.nu;
		jj = ./nushell/jj.nu;
		kubectl = ./nushell/kubectl.nu;
		loadEnv = ./nushell/load_env.nu;
		misc = ./nushell/misc.nu;
		notes = ./nushell/notes.org;
		resiliency = ./nushell/resiliency.nu;
		screens = ./nushell/screens.nu;
		ssh = ./nushell/ssh.nu;
		testsMod = ./nushell/tests_mod.nu;
		updatePath = ./nushell/update_path.nu;
		vms = ./nushell/vms.nu ;
	  };

	  jujutsu = ./jj/config.toml;
	  vim = ./vim;
	  dunst = ./dunst;
	  terminator = ./terminator;
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
		hardwareConfiguration = ./nix/qemu-hardware-configuration.nix;
		bootloaderDevice = "/dev/sda";
	  };

	  # The qemu virtual machine on the work laptop.
	  workQemuVm = {
		hostname = "work-qemu-william";
		hardwareConfiguration = ./nix/work-qemu-hardware-configuration.nix;
		bootloaderDevice = "/dev/vda1";
	  };

	  # Any machine whose hostname we wish to change. Need to build-switch nixos
	  # with this, then reboot, and the machine will have a different hostname.
	  # Feel free to change [hostname] (the current one) and [hostnameOverride]
	  # (the target hostname) to do this. No machine will (or can) use this
	  # config long-term.
	  hostRename = {
		hostname = "mountain-lightning-on-the-net";
		hostnameOverride = "work-qemu-william";
		hardwareConfiguration = inputs.self.nixosModules.hardware.workQemuVm.hardwareConfiguration;
		bootloaderDevice = inputs.self.nixosModules.hardware.workQemuVm.bootloaderDevice;
	  };
	};

	utils = import ./nix/utils.nix;
  };
}
