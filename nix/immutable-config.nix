# =====================================================
# =====================================================
# ========= THESE ARE UNLIKELY TO EVER CHANGE =========
# =====================================================
# =====================================================

{
  # Enable flakes: run `sudo nix-rebuild switch` with this, then you'll be using
  # flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable gnome-keyring secret vault.
  services.gnome.gnome-keyring.enable = true;

  # A fine-control privilege controller (needed to configure sway with
  # home-manager).
  security.polkit.enable = true;

  # Sound config
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.openssh.enable = true;
  services.qemuGuest.enable = true;

  networking.hostName = "william-on-the-net";
  networking.networkmanager.enable = true;

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = 10;

  time.timeZone = "Europe/London";
  services.xserver.xkb.layout = "us";
  services.printing.enable = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
	LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };


  nixpkgs.config.allowUnfree = true;  

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .

  # TODO: This is where system.stateVersion goes. That isn't safe to just change
  # on my own, so let the OS generate it, then fill it in here, then remove the
  # OS's file and link this one from there. Or something.
}