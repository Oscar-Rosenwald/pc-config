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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = 10;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/London";
  services.xserver.xkb.layout = "us";
  services.printing.enable = true;

  nixpkgs.config.allowUnfree = true;  

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # TODO: This is where system.stateVersion goes. That isn't safe to just change
  # on my own, so let the OS generate it, then fill it in here, then remove the
  # OS's file and link this one from there. Or something.
}