all: result

result: $(shell find $(SRC_DIRS) -name '*.nix' -type f)
	nix-build ${NIX_ARGS} '<nixpkgs/nixos>' -A config.system.build.toplevel -I nixos-config=./configuration.nix

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
