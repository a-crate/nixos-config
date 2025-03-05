branch ?= main

all: result

result: build/configuration.nix build/hardware-configuration.nix build/machine.nix
	nix-build '<nixpkgs/nixos>' -A config.system.build.toplevel -I nixos-config=./configuration.nix

build/configuration.nix:
	mkdir -p build
	ln -s ../configuration.nix build/configuration.nix

build/hardware-configuration.nix:
	mkdir -p build
	ln -s ../hardware-configuration.nix build/hardware-configuration.nix

build/machine.nix:
	mkdir -p build
	ln -s ../machine.nix build/machine.nix

# Link hardware-configuration.nix and machine.nix to system files for building
local-links: local-hardware-configuration.nix local-machine.nix

# Link hardware-configuration.nix to system file for building
local-hardware-configuration.nix:
	ln -s /etc/nixos/hardware-configuration.nix ./hardware-configuration.nix

# Link machine.nix to system file for building
local-machine.nix:
	ln -s /etc/nixos/machine.nix ./machine.nix

deploy: result
	sudo ./deploy.sh
	sudo nixos-rebuild switch

clean:
	rm -rf ./build
	rm -rf ./result
