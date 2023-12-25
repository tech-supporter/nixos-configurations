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
      ./server-configuration.nix
      ./wireguard-client-configuration.nix
      ./nfs-configuration.nix
    ];

  config.server-configuration.address = "10.0.0.4";

  config.networking.hostName = "torrent";

  config.nfs-configuration.paths =
  [
    "torrent"
    "media"
  ];

  config.users.groups.media = 
  {
    gid = 72;
  };

  config.users.users.media =
  {
    isNormalUser = false;
    isSystemUser = true;
    uid = 72;
    home  = "/";
    description = "Media Management User";
    group = "media";
  };

  config.nfs-configuration.storageUsers = 
  [ 
    "media"
  ];

  # hacky service until nixos figures out how to get services to wait for file systems
  # https://github.com/NixOS/nixpkgs/issues/217179
  #config.systemd.services.filesystemready = {
  #  after = [ "network.target" ];
  #  wantedBy = [ "multi-user.target" ];
  #  serviceConfig = {
  #    Type = "oneshot";
  #    ExecStart = "${pkgs.bash}/bin/bash -c 'until [[ -f /mnt/nfs/media/mounted ]] && [[ -f /mnt/nfs/torrent/mounted ]]; do sleep 1; done'";
  #  };
  #};

  #config.systemd.services.transmission.after = [ "filesystemready.service" ];
  #config.systemd.services.radarr.after = [ "filesystemready.service" ];
  #config.systemd.services.sonarr.after = [ "filesystemready.service" ];

  config.systemd.services.transmission.unitConfig = {
    RequiresMountsFor = "/mnt/nfs/media/media /mnt/nfs/torrent/transmission";
  };
  config.systemd.services.radarr.unitConfig = {
    RequiresMountsFor = "/mnt/nfs/media/media /mnt/nfs/torrent/transmission";
  };
  config.systemd.services.sonarr.unitConfig = {
    RequiresMountsFor = "/mnt/nfs/media/media /mnt/nfs/torrent/transmission";
  };

  config.wireguard-client-configuration =
  {
    ips = ["10.65.252.122/32"];
    port = 51820;
    endpoint = "68.235.43.130";
    privateKeyFile = "/secrets/keys/wireguard/private/mullvad.key";
    peerPublicKey = "dr0ORuPoV9TYY6G5cM00cOoO72wfUC7Lmni7+Az9m0Y=";
    prefixLength = config.server-configuration.prefixLength;
  };

  config.networking.firewall.allowedTCPPorts = [ ];

  config.environment.systemPackages = [
    pkgs.radarr
    pkgs.sonarr
    pkgs.prowlarr
    pkgs.transmission
  ];

  config.services.radarr =
  {
    enable = true;
    openFirewall = true;
    user = "media";
    group = "media";
    dataDir = "/mnt/nfs/torrent/radarr";
  };

  config.services.sonarr =
  {
    enable = true;
    openFirewall = true;
    user = "media";
    group = "media";
    dataDir = "/mnt/nfs/torrent/sonarr";
  };

  config.services.prowlarr =
  {
    enable = true;
    openFirewall = true;
  };

  # work around for transmission path issue
  # config.systemd.services.transmission.serviceConfig.BindReadOnlyPaths = pkgs.lib.mkForce [ builtins.storeDir "/etc" ];

  config.services.transmission =
  {
    enable = true;
    openFirewall = true;
    openRPCPort = true;
    user = "media";
    group = "media";
    #downloadDirPermissions = "770";
    #home = "/mnt/nfs/torrent/transmission";
    settings =
    {
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = false;
      rpc-authentication-required = true;
      rpc-username = "techsupporter";
      rpc-password = builtins.readFile "/secrets/passwords/transmission/rpc.txt";
      incomplete-dir-enabled = true;
      incomplete-dir = "/mnt/nfs/torrent/transmission/downloading";
      download-dir = "/mnt/nfs/torrent/transmission/downloaded";
    };
  };

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
