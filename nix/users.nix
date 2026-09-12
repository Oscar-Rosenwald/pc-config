{
  users.users.william = {
	isNormalUser = true;
	initialPassword = "pass";
	extraGroups = [
      "wheel" # gives root privileges
      "networkmanager" # allows changing network configs
      "video"
	  "docker"
	];
  };
}