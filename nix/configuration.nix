{ config, pkgs, ... }: # other options are: lib, options, and inputs

{
  imports = [
	/etc/nixos/hardware-configuration.nix
	./immutable-config.nix # Stuff which changes very rarely
	./users.nix # User configuration
	./wayland.nix
  ];

  # Which packages to install system-wide
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    firefox
    terminator
	flameshot # Screenshots
	wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    foot # Sway terminal
    waybar # Sway status bar
    wofi # App launcher
    wl-clipboard # Clipboard for Wayland
    nushell
    jujutsu
    eza
    vivaldi
    google-chrome
    slack
    gimp
    inkscape
    bat
    eza # Better ls
    fzf # Fuzzy finder
    carapace
	nnn # terminal file manager
	zip
	unzip
	dnsutils
	file
	which
	tree
	whereis
	nix-output-monitor # "nom" is like "nix" but better output
	glow # markdown highlighting in terminal
	top
	lsof
  ];

  # TODO This is hella unfinished.
}