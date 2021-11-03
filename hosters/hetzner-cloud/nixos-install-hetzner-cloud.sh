#! /usr/bin/env bash

# Script to install NixOS from the Hetzner Cloud NixOS bootable ISO image.
# (tested with Hetzner's `NixOS 20.03 (amd64/minimal)` ISO image).
#
# This script wipes the disk of the server!
#
# Instructions:
#
# 1. Mount the above mentioned ISO image from the Hetzner Cloud GUI
#    and reboot the server into it; do not run the default system (e.g. Ubuntu).
# 2. To be able to SSH straight in (recommended), you must replace hardcoded pubkey
#    further down in the section labelled "Replace this by your SSH pubkey" by you own,
#    and host the modified script way under a URL of your choosing
#    (e.g. gist.github.com with git.io as URL shortener service).
# 3. Run on the server:
#
#       # Replace this URL by your own that has your pubkey in
#       curl -L https://raw.githubusercontent.com/sumnerevans/nixos-install-scripts/master/hosters/hetzner-cloud/nixos-install-hetzner-cloud.sh | sudo bash
#
#    This will install NixOS and power off the server.
# 4. Unmount the ISO image from the Hetzner Cloud GUI.
# 5. Turn the server back on from the Hetzner Cloud GUI.
#
# To run it from the Hetzner Cloud web terminal without typing it down,
# you can either select it and then middle-click onto the web terminal, (that pastes
# to it), or use `xdotool` (you have e.g. 3 seconds to focus the window):
#
#     sleep 3 && xdotool type --delay 50 'curl YOUR_URL_HERE | sudo bash'
#
# (In the xdotool invocation you may have to replace chars so that
# the right chars appear on the US-English keyboard.)
#
# If you do not replace the pubkey, you'll be running with my pubkey, but you can
# change it afterwards by logging in via the Hetzner Cloud web terminal as `root`
# with empty password.

set -e

# Hetzner Cloud OS images grow the root partition to the size of the local
# disk on first boot. In case the NixOS live ISO is booted immediately on
# first powerup, that does not happen. Thus we need to grow the partition
# by deleting and re-creating it.
sgdisk -d 1 /dev/sda
sgdisk -N 1 /dev/sda
partprobe /dev/sda

mkfs.ext4 -F /dev/sda1 # wipes all data!

mount /dev/sda1 /mnt

nixos-generate-config --root /mnt

# Delete trailing `}` from `configuration.nix` so that we can append more to it.
sed -i -E 's:^\}\s*$::g' /mnt/etc/nixos/configuration.nix

# Extend/override default `configuration.nix`:
echo '
  boot.loader.grub.devices = [ "/dev/sda" ];

  # Initial empty root password for easy login:
  users.users.root.initialHashedPassword = "";
  services.openssh.permitRootLogin = "prohibit-password";

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    # Replace this by your SSH pubkey!
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDcO1lMaMPbL2cr4XdKc6bQJIbQylIXaYfX0S+NN3z0AMw3HCfsNCwlWoxyjIbZBlP3aSrdTITq3eB0gw3l25029h3Q4Dve+I2hf6jpltaGVlpsyhMN8xu9yoqadd0cG71kn6Wn5/BlpaWZtrJy7Px9luCyeuDx+vkC05CLb28sjwYVdTzbuePygUONL7cH6Xd2ulLDW+dFoZIHwraEsqHk9AQRV3f2hokxG/VpbxbVAY7XNOkIrsfmX6y4IccUddffgs8uqsObHEWniPdWOcEocRJ4exORBoyS5SXvcHzUtGi8Q0jGPfKkSFPEYUNcgw0QlU4dzrT/xqm0COcOoXKK58+tZH/YMu0bshp+vIK3HDCCfcRtuv1ZMF/AFbHdY3fglUu3YK2Jpm5Vr8KzljqQXW3ekboILxZpuP2LA3YErS1lpaj3sbOlsfxNQhG7V8/gqo1PBQ4w//7wlav0TOY5GZD1Tw2lduaSAFuFHxVGBOy4Xu31mxa2Qej5YKc71VU= sumner@coruscant"
  ];
}
' >> /mnt/etc/nixos/configuration.nix

nixos-install --no-root-passwd

poweroff
