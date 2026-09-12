#!/usr/bin/env nu

# Carapace-bin is a binary which implements completion for basically every
# command on the planet in basically every shell. I installed it by adding
#
#  deb [trusted=yes] https://repo.fury.io/rsteube/ /
#
# to file /etc/apt/sources.list.d/fury.list and running sudo apt update and
# install.

# From the carapace-bin setup guide, I'm supposed to add these lines into my
# config, but I don't see why the first two have to be evaluated every time I
# launch nushell unless the cache dir is removed on boot, which, let's face it,
# would be dumb. So I commented them out here and am hoping for the best. They
# ARE needed for new installataions

# mkdir $"($nu.cache-dir)"
# carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
source $"($nu.cache-dir)/carapace.nu"
