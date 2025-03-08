# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config, lib, pkgs, ... }:
let
  pkgs = import <nixpkgs> {
    config = import ./pkgs;
  };
  # Machine identity information (hostname, hostid, machine-specific configuration)
  machine = import ./machine.nix;
  haveNvidiaGPU = builtins.elem "nvidia" machine.gpu;
  haveIntelGPU = builtins.elem "intel" machine.gpu;
  haveAMDGPU = builtins.elem "amd" machine.gpu;
  haveDGPU = haveNvidiaGPU || haveIntelGPU;
  gpuDrivers = []
    ++(if haveAMDGPU then [ "amdgpu" ] else [])
    ++(if haveIntelGPU then [ "i915" ] else [])
    ++(if haveNvidiaGPU then [ "nvidia" ] else []);
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  networking.hostName = machine.hostName;
  networking.hostId = machine.hostId;

  # Include stuff for docking stations in initrd
  boot.initrd.availableKernelModules = [ "xhci_pci" "xhci_hcd" "nvme" "usbhid" "usb_storage" "uas" "sd_mod" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  networking.networkmanager.enable = true;
  boot.initrd.kernelModules = [] ++ gpuDrivers;
  time.timeZone = "America/Los_Angeles";

  services = {
    ollama = {
      enable = haveDGPU;
      acceleration = if haveAMDGPU then "rocm" else if haveNvidiaGPU then "cuda" else false;
      # nix-run -p rocmPackages.rocminfo rocminfo | grep gfx
      # run on gfx1031, or 10.3.1
      # hardcoded to my 6700 right now...
      environmentVariables.HCC_AMDGPU_TARGET = if haveAMDGPU then "gfx1031" else "";
      rocmOverrideGfx = if haveAMDGPU then "10.3.1" else "";
    };
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
      };
    };
    pipewire = {
      #enable = true;
      #pulse.enable = true;
    };
    gvfs.enable = true; # Mount, trash, and other functionalities
    tumbler.enable = true; # Thumbnail support for images
    gnome.gnome-keyring.enable = true;
    xserver.videoDrivers = gpuDrivers;
  };

  systemd.packages = if haveAMDGPU then [ pkgs.lact ] else [];
  systemd.services.lactd.wantedBy = if haveAMDGPU then ["multi-user.target"] else [];


  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = if haveAMDGPU then [ pkgs.amdvlk ] else [];
      extraPackages32 = if haveAMDGPU then [ pkgs.driversi686Linux.amdvlk ] else [];
    };
    pulseaudio = {
      package = pkgs.pulseaudioFull;
    };
    bluetooth = {
      enable = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };
  virtualisation.libvirtd.enable = true;
  programs = {
    gamemode.enable = haveDGPU;
    virt-manager.enable = true;
    light.enable = true;
    fish.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ];
    };
    xfconf.enable = true;
    sway.enable = true;
    steam = {
      enable = haveDGPU;
      remotePlay.openFirewall = haveDGPU;
      localNetworkGameTransfers.openFirewall = haveDGPU;
    };
  };

  users.users.root.shell = pkgs.fish;
  users.groups.amy = {};
  users.users.amy = {
    shell = pkgs.fish;
    isNormalUser = true;
    group = "amy";
    extraGroups = [ "wheel" "networkmanager" "video" "libvirtd" ];
    packages = with pkgs; [
      onlyoffice-bin
      sway
      git
      gh
      swaybg
      alacritty
      swayidle
      waybar
      wob
      swaylock
      wl-clipboard
      sway-launcher-desktop
      swaynotificationcenter
      keepassxc
      librewolf
      grim
      slurp
      playerctl
      waybar
      gajim
      nextcloud-client
      font-awesome
      pulseaudio
      discord
      kanshi
      any-nix-shell
    ];
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    kakoune
    vim
    wget
    curl
    lact
    gnumake
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    font-awesome
    source-han-sans
    source-han-sans-japanese
    source-han-serif-japanese
  ];

  # Open ports in the firewall.
  #networking.firewall.allowedTCPPorts = [ ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;
  nixpkgs.config.allowUnfree = true;
  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}

