# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./boot-uefi-configuration.nix
      ./network-configuration.nix
      ./base-configuration.nix
    ];

  config.nixpkgs.config.allowUnfree = true;

  config.hardware.cpu.intel.updateMicrocode = true;
  config.hardware.opengl = {
    ## radv: an open-source Vulkan driver from freedesktop
    driSupport = true;
    driSupport32Bit = true;

    ## amdvlk: an open-source Vulkan driver from AMD
    extraPackages = [ pkgs.rocmPackages.clr.icd ];
    #extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
  };

  config.boot.initrd.kernelModules = [ "amdgpu" ];

    # Make some extra kernel modules available to NixOS
  config.boot.extraModulePackages = with config.boot.kernelPackages;
    [ v4l2loopback.out ];

  # Activate kernel modules (choose from built-ins and extra ones)
  config.boot.kernelModules = [
    # Virtual Camera
    "v4l2loopback"
    # Virtual Microphone, built-in
    "snd-aloop"
  ];

  # Set initial kernel module settings
  config.boot.extraModprobeConfig = ''
    # exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming
    # card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
    # https://github.com/umlaeute/v4l2loopback
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';


  config.networking.hostName = "techsupporter-pc";
  config.networking.networkmanager.enable = true;

  # Select internationalisation properties.
  config.i18n.defaultLocale = "en_US.UTF-8";
  config.console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    #useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable the X11 windowing system.
  config.services.xserver.enable = true;
  config.services.xserver.videoDrivers = [ "amdgpu" ];

  config.services.xserver.displayManager.sddm.enable = true;
  config.services.xserver.desktopManager.plasma5.enable = true;
  config.services.xserver.desktopManager.plasma5.useQtScaling = true;

  # Configure keymap in X11
  config.services.xserver.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  config.services.printing.enable = true;

  # Enable sound.
  config.sound.enable = true;
  config.hardware.pulseaudio.enable = true;

  config.virtualisation.libvirtd.enable = true;
  config.programs.virt-manager.enable = true;

  config.users.users.techsupporter.extraGroups = [ "libvirtd" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  config.environment.systemPackages = with pkgs; [
    libsForQt5.plasma-vault
    libsForQt5.skanpage
    librewolf
    ungoogled-chromium
    vlc
    gimp
    ffmpeg_6-full
    yt-dlp
    nextcloud-client
    libreoffice-qt
    hunspell
    hunspellDicts.en_US
    vscodium
    kate
    discord
    cryfs
    ksnip
    audacity
    #obs-studio
    freecad
  ];

  config.services.flatpak.enable = true;

  #config.programs.steam = {
  #  enable = true;
  #  remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  #  dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  #};

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  config.system.stateVersion = "23.11"; # Did you read the comment?
}
