#!/usr/bin/env nix-shell
#! nix-shell -i bash -p bash
#
# Push to /etc/nixos.
#

for file in *.nix; do
	case $file in
		shell.nix|hardware-configuration.nix|machine.nix)
			echo "not moving $file"
			;;
		*)
			if [ -f /etc/nixos/$file ]; then
				echo "/etc/nixos/$file already exists, moving to /etc/nixos/$file.old"
				mv "/etc/nixos/$file" "/etc/nixos/$file.old"
			fi
			cp $file /etc/nixos
			;;
	esac
done

chown -R root:root /etc/nixos/
chmod 644 /etc/nixos/*.nix
