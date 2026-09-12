{
  # Sway configuration
  programs.sway =  { 
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # Wayland - screen sharing
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };
}