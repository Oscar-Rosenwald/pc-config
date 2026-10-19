#!/usr/bin/env nix-shell
#! nix-shell -i nu --pure
#! nix-shell -p nushell vim git jujutsu lolcat

if ('/etc/nixos-original' | path exists) {
  print "Found another directory that claims to be the nixos original configuration."
  print "You should look into that. I won't do shit with two 'originals'."
  return 1
}

def log [line: string] {
  $"($line)\n" | lolcat
}

let me = whoami
let configRepoPath = $"/home/($me)/pc-config"
let thisPcName = input "What does your nix hardware config call this computer?"

log "Adding certificates to git"
# This is needed because git sometimes just panics for no reason.
git config --global http.sslCAInfo /etc/ssl/certs/cacertificates.crt

if ($configRepoPath | path exists) {
  log $"Removing old ($configRepoPath)" # In case we need to run the script again.
  rm -rf $configRepoPath
}

log $"Cloning configuration repository to ($configRepoPath)"
# Note that you won't be able to push here because it's not the SSH address.
jj git clone https://github.com/Oscar-Rosenwald/pc-config.git $configRepoPath

log "Moving the default nixos configuration out of the way"
sudo mv /etc/nixos /etc/nixos-original

log "Ensuring your custom configuration knows what computer this is"
open $"($configRepoPath)/nix/flake.nix"
  | str replace -r 'hostRename = self.hardware.* //' $"hostRename = self.hardware.($thisPcName) //"
  | save --force $"($configRepoPath)/nix/flake.nix"

log "Copying this machine's hardware configuration file to your custom configs"
cp -i /etc/nixos-original/hardware-configuration.nix $"($configRepoPath)/nix/($thisPcName)-hardware-configuration.nix"

log "Putting custom nixos configuration in place so Nix can boot from it"
sudo ln -s $"($configRepoPath)/nix" /etc/nixos

log "Cloning Emacs configuration file"
cp ~/pc-config/emacs/.emacs ~/.emacs

log "Stand by. Your OS is in the oven..."
sudo nixos-rebuild --flake /etc/nixos switch

"Done. Yay!" | lolcat