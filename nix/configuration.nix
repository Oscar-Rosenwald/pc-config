# This config file is called by a util function which passes to it all the
# arguments. The util function is called by the nixos configuration flake,
# which calls the util function repeatedly, once for every hostname defined
# in the config flake (i.e., my config repository) under the hardware
# attribute.
#
# - specialArgs:
#     - hardwareConfigurationFile: path to the hardware configuration file
#       Dependent on the host we're using.

{
  config,
  specialArgs,
  pkgs,
  ... # other options are: lib, inputs, and options
}: 

{
  imports = [
    specialArgs.hardwareConfigurationFile
    ./immutable-config.nix # Stuff which changes very rarely
    ./users.nix # User configuration
    ./wayland.nix # Display manager and window manger configs
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
    nix-output-monitor # "nom" is like "nix" but better output
    glow # markdown highlighting in terminal
    lsof
  ];
}
