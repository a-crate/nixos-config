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
			cp $file /etc/nixos/$file
			;;
	esac
done

if [ -d /etc/nixos/pkgs ]; then
	echo "/etc/nixos/pkgs already exists, moving to /etc/nixos/pkgs.old"
	rm -rf "/etc/nixos/pkgs.old"
	mv "/etc/nixos/pkgs" "/etc/nixos/pkgs.old"
fi
cp -r pkgs /etc/nixos/pkgs

chown -R root:root /etc/nixos/
chmod 644 /etc/nixos/*.nix
chmod 644 /etc/nixos/pkgs
chmod 644 /etc/nixos/pkgs/*.nix
