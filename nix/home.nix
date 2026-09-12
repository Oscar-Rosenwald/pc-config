# This file describes the home-manager configuration. INPUTS contains a myConfigDir attribute which
# is the absolute path to the place where my git config is downloaded.

{ inputs, ... }:

let
  # Path to my directory of configurations (in the nix store, because duh).
  myConfigDir = inputs.myConfigDir;

  sshDir = ~/.ssh/;
  sshDefaultIdentity = /${sshDir}/id_ed25519;
  sshGithubWorkIdentity = /${sshDir}/github;
in
{
  home.username = "william";
  home.homeDirectory = "/home/william";
  home.stateVersion = "26.05";

  # This comes from carapace's docs. We must produce the init.nu file for
  # nushell so that it can call it with command-line arguments.
  home.file.".cache/nushell/carapace/init.nu".source = pkgs.runCommand "carapace-init" {} ''
	${pkgs.carapace}/bin/carapace _carapace nushell > $out
  '';

  programs.git = {
	enable = true;
	username = "William Stratfel";
  };

  # Nushell configuration
  programs.nushell = {
    enable = true;

	configFile.text = ''
	  source ${myConfigDir}/code/nushell/load_env.nu
	  source ${myConfigDir}/code/nushell/update_path.nu

      source ${myConfigDir}/code/nushell/misc.nu
      source ${myConfigDir}/code/nushell/chdir.nu
      source ${myConfigDir}/code/nushell/docker.nu
      source ${myConfigDir}/code/nushell/vms.nu
      source ${myConfigDir}/code/nushell/external.nu

      use ${myConfigDir}/code/nushell/git.nu *
      use ${myConfigDir}/code/nushell/grep.nu *  # TODO missing gg
      use ${myConfigDir}/code/nushell/tests_mod.nu *
      use ${myConfigDir}/code/nushell/screens.nu *
      use ${myConfigDir}/code/nushell/resiliency.nu *
      use ${myConfigDir}/code/nushell/jj.nu *
      use ${myConfigDir}/code/nushell/ssh.nu *
      use ${myConfigDir}/code/nushell/kubectl.nu *

      source ${myConfigDir}/code/nushell/aliases.nu
	'';

	# This completion config comes from carapace's docs. See above for where
	# init.nu comes from.
    extraConfig = "source ($nu.cache-dir | path join carapace/init.nu)";
	environmentVariables.CARAPACE_BRIDGES = "'zsh,fish,bash,inshellisense'";

	settings = {
	  show_banner = false;
	  history = {
		file_format = "sqlite";
		isolation = true;
	  };
	};
  };

  programs.bash = {
	enable = true;
	enableCompletion = true;

	# TODO Do we need to do this?
	# Configuring right alt to be the compose key. There are a few issues with it,
	# so we need to do it in this weird way. Blame Gemini for this mess.
	profileExtra = ''
      export GTK_IM_MODULE=none
      export QT_IM_MODULE=xim
      export XMODIFIERS="@im=none"
    '';

	shellAliases = {
	  "ls" = "ls --color=auto -G";
	  "ll" = "ls -alFvG";
	  "la" = "ls -Av";
	  "l"  = "ls -CFv";
	  "l1" = "ls -1vt";
	  "lt" = "ls -1vt";
	  "mv" = "mv -i";
	  "beep" = "paplay -n synth 0.2 sine 1000 vol 0.2";
	  "fireb" = "firefox -p blabla 2>/dev/null &";
	};
  };

  programs.jujutsu.enable = true;
  home.file.".config/jj/" = {
	enable = true;
	source = /${myConfigDir}/jj;
  };

  home.file.".vim" = {
	enable = true;
	source = /${myConfigDir}/.vim;
  };

  home.file.".ssh/" = {
	enable = true;
	source = /${myConfigDir}/.ssh;
  };

  programs.ssh = {
	enable = true;
	settings = {
	  # Credentials for my personal GitHub account.
	  "oscar.github.com" = {
		HostName = "github.com";
		IdentityFile = "${sshDefaultIdentity}";
		ForwardAgent = "yes";
	  };

	  # Credentials for my work GitHub account.
	  "tom.github.com" = {
		HostName = "github.com";
		PreferredAuthentications = "publickkey";
		IdentityFile = "${sshGithubWorkIdentity}";
	  };

	  # Default credentials.
	  "*" = {
		IgnoreUnknown = "UseKeychain";
		AddKeysToAgent = "yes";
		IdentityFile = "${sshDefaultIdentity}";
		StrictHostKeyChecking = "no";
	  };
	};
  };

  programs.git = {
	enable = true;
	lfs.enable = true;
	config = {
	  user = {
		email = "cyril.saroch@motorolasolutions.com";
		name = [ cyril.saroch Cyril ];
		url."git@repo.jazznetworks.com:".insteadOf = "https://repo.jazznetworks.com/";
	  };
	  core.editor = "emacsclient --create-frame";
	  # TODO git/contrib won't be in this path.
	  # credential.helper = /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret;
	  pull.rebase = false;
	  push.recurseSubmodules = false;
	  submodule.recurse = true;
	  init.defaultBranch = "master";
	};
  };

  home.file.".sqliterc".text = ''
    .m box
  '';

  home.file."config/dunst/".source = /${myConfigDir}/dunst;

  programs.terminator.enable = true;
  home.file."config/terminator".source = /${myConfigDir}/terminator;

  wayland.windowManager.sway = {
	enable = true;
	# TODO: config = { ... }; See home-manager/modules/services/window-managers/i3-sway/sway.nix
  };
}