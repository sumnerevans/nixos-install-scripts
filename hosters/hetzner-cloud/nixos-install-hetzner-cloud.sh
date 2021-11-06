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
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDasJXb4uvxPh0Z1NLa22dTx42VdWD+utRMbK0WeXS6XakIipx1YPb4yqbtUMJkoTLuFW/BUAEXSiks+ARD3Lc4K/iJeHHXbYvgklvr5dAPV6P2KtiVRZ+ipSLv1TF+al6hVUAnp4PPUQTv+3ZRA64QFrCAt26A7OnxKlowyW2KZVSqAcWPdQEbCdwILRCRIWTpbSj1rDeEsnvmu1G+Id5v7+uybQ+twBHbGpfYH7yWYLEhDtRyYu5SgnBcEh0bqszEgt+iLH/XzTQJILKdDaf4x8j/FJ9Px7+VQVfc+yADZ882ZsFzaxlmn7ndstAssmSSsHfRmNye0exIJqGXdxUfpF3w4h5qnR/0AJM7ljtXuDNOlOxflX0WvZinhhOJ/gF3No8sCXG/OcqlMNyrWd+vpJH4f9Xa0PTOn3Qpltq3YxWOZrWopUIDZw5jSsgLpLfC2NtGE/p5nEFnJCmMqrXPDY7dYS+65qYYjWXCzY3d9i3offwIQtV780Gu1VvT/zE= sumner@coruscant"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDcO1lMaMPbL2cr4XdKc6bQJIbQylIXaYfX0S+NN3z0AMw3HCfsNCwlWoxyjIbZBlP3aSrdTITq3eB0gw3l25029h3Q4Dve+I2hf6jpltaGVlpsyhMN8xu9yoqadd0cG71kn6Wn5/BlpaWZtrJy7Px9luCyeuDx+vkC05CLb28sjwYVdTzbuePygUONL7cH6Xd2ulLDW+dFoZIHwraEsqHk9AQRV3f2hokxG/VpbxbVAY7XNOkIrsfmX6y4IccUddffgs8uqsObHEWniPdWOcEocRJ4exORBoyS5SXvcHzUtGi8Q0jGPfKkSFPEYUNcgw0QlU4dzrT/xqm0COcOoXKK58+tZH/YMu0bshp+vIK3HDCCfcRtuv1ZMF/AFbHdY3fglUu3YK2Jpm5Vr8KzljqQXW3ekboILxZpuP2LA3YErS1lpaj3sbOlsfxNQhG7V8/gqo1PBQ4w//7wlav0TOY5GZD1Tw2lduaSAFuFHxVGBOy4Xu31mxa2Qej5YKc71VU= sumner@coruscant-nixos"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDPswA82WA6tHR8rccfVrmBflIfC9SmZpG1Y+Gr8WPxcMy/fdlOt8zV4FveUA466pu9oOsZKmuz8WlP2RK96mhhf/CB68QyPAObo6NyIKQgDC97owRGpNtGTUw4bWdGT+9VKDcuoJdK0cI1dY3jrhIgKL43rOfBnhJfDEBWpRJFof79AfN+Zcs1hTprCjPbiHdXuc7E+uhvxdKfoC2lTDYneVNFUBubcH6SSCJ27AZURPca2aSMkWgGCVTom1ch4Y8jZ5e6Kg0pNZW8LQoLC/kzdwC/f8DHXPFSFipVP5jJ6qtXWm0WCY62nsuV6GyphmmC2H25gV3GefD1ano2pJixRMfj8Muvwm+XKXD7GqmprEKMr0KZjkMGKq144T31TWG/LXkRKuGmHf9wNx4gmFTr6stG30nDYlhaMf/jpeoSAPV9o48x6DZqgd+ukQHKG/uXIYU9gj6OtFOi5bJQp+64P1pBc78942PdnvgC4Bk2sqOyj8nPFeFZKAURctib38U= sumner@jedha"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9J5GLv9e/k1yDFw/pWyGFcHeRaLMI3j22ihQfGKgfX9Kl3X/R2s5+4a4c98PbPeeO0WlFvu0JiwhT1MLb5Kk5iLxVf8C32kNPQ0kLpa+g/L7YSsvYMThUF8qcLhw0imDVEye4gKrKc6uQDwaCr/Rd+93elfeZ+OQj34czWV1vf4Tnpiad7WZ0IVklN5GQTdVTVPDzjiLaKgl/f3E/wv7DYibDUwwdCBWxo+4RJ9QbSwbgxQykLe3TOydPbwyIk5jmGSdNjtxhT4223lVZICBD2AYf23ERPZz/VtPZvF4qv+55C9YjoatAlW68esKTV3X2qV7K19RbeD58N8Yk16SMgs/HyLzXk4L1pPVNMZVAKX7nqNWnn12VMzHa+DJsEBvcnzwaGsBqEuf3fPzP7Isp9IKwQcBEF+mM1UgGRx8OA5tYt9vOnXtYJG+nOkupfga/fT1Zl9Imao+B0Gz1gG6ywM6bxUr5kkjvuQggc4J6pTslG11IQrnBll7k04vKDtM= sumner@mustafar"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvaDJ6+y5F9vh1EsE2/QUrGmNhZpLOpJ92Gf5JI7QtgEW7tlroj8kAKEZlqOp2U7IsxFqyBUc4NMdWDmDXsvEV3d2tNXt9olL169wceRhgIA/dtibiQktWhvRAFQ5NpBVkCw8r2ZJHp7gp1sPbraikHGVVfA4ybK9C4HI21uehLSmKMcN9X9fD3ONI9HOBDMX7KDm/qy1etLXIoC7ZiGNOw85g4B1PogjzKoiPv3RmyprO6pCDVjpTSKqzVzaWzkYIavOyzHWFjdE6turbcf3Hd9pMPkbrt+0ZQtctqjkj9LZGuO2Ug9QHGKz8hhcmEh2gbzj7UPHW5hC7SfgjmHb7ra1uhi+M55O6C59ksC8GBDPus2xC8nswjlN1UPoA4YFvObhHTvtrVc1gEXTgCqKuslAvc2vg/Yy3hkhS5Xkkpkq5RDVTDix3yM0XKqvt/KB4wTMlRQ+IzkTK376PsEKcPDgYYZA/G/wRl2cQtDa1Rc0+UjSTfeUqFgjdmxltcQk= sumner-nix-remote-build@mustafar"
  ];
}
' >> /mnt/etc/nixos/configuration.nix

nixos-install --no-root-passwd

poweroff
