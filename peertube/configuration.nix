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
      ./nfs-configuration.nix
    ];

  config.server-configuration.address = "10.0.0.15";

  config.networking.hostName = "peertube";
  
  config.nfs-configuration.paths = [ "peertube" ];
  config.nfs-configuration.storageUsers = 
  [
    "peertube"
    "postgres"
  ];

  config.users.users.postgres.uid = 71;
  config.users.groups.postgres.gid = 71;

  config.users.users.peertube.uid = 73;
  config.users.groups.peertube.gid = 73;

  config.networking.firewall.allowedTCPPorts = [ 9000 ];

  config.environment.systemPackages = [
    pkgs.peertube
    pkgs.postgresql
  ];

  config.services = {

    peertube = {
      enable = true;
      localDomain = "peertube.techsupporter.net";
      enableWebHttps = true;
      listenWeb = 443;
      dataDirs = [ "/mnt/nfs/peertube/peertube/storage" ];
      smtp.passwordFile = "/secrets/passwords/email/email.txt";
      database = {
        host = "127.0.0.1";
        name = "peertube";
        user = "peertube";
        passwordFile = "/secrets/passwords/postgresql/peertube.txt";
      };
      redis = {
        host = "127.0.0.1";
        port = 31638;
        passwordFile = "/secrets/passwords/redis/redis.txt";
      };
      settings = {
        listen.hostname = "0.0.0.0";
        instance.name = "Techsupporter PeerTube Server";
        trust_proxy = [ "10.0.0.8" ];
        admin = {
          email = "admin@techsupporter.net";
        };
        storage = {
          avatars = "/mnt/nfs/peertube/peertube/storage/avatars/";
          bin = "/mnt/nfs/peertube/peertube/storage/bin/";
          cache = "/mnt/nfs/peertube/peertube/storage/cache/";
          captions = "/mnt/nfs/peertube/peertube/storage/captions/";
          client_overrides = "/mnt/nfs/peertube/peertube/storage/client-overrides/";
          logs = "/mnt/nfs/peertube/peertube/storage/logs/";
          plugins = "/mnt/nfs/peertube/peertube/storage/plugins/";
          previews = "/mnt/nfs/peertube/peertube/storage/previews/";
          redundancy = "/mnt/nfs/peertube/peertube/storage/redundancy/";
          streaming_playlists = "/mnt/nfs/peertube/peertube/storage/streaming-playlists/";
          thumbnails = "/mnt/nfs/peertube/peertube/storage/thumbnails/";
          tmp = "/mnt/nfs/peertube/peertube/storage/tmp/";
          tmp_persistent = "/mnt/nfs/peertube/peertube/storage/tmp_persistent/";
          torrents = "/mnt/nfs/peertube/peertube/storage/torrents/";
          videos = "/mnt/nfs/peertube/peertube/storage/videos/";
          well_known = "/mnt/nfs/peertube/peertube/storage/well_known/";
        };
        # Only created if the original video has a higher resolution, uses more storage!
        resolutions = {
          "0p" = true; # audio-only (creates mp4 without video stream, always created when enabled)
          "144p" = true;
          "240p" = true;
          "360p" = true;
          "480p" = true;
          "720p" = true;
          "1080p" = true;
          "1440p" = true;
          "2160p" = true;
        };        
        smtp = {
          # smtp or sendmail
          transport = "smtp";
          # Path to sendmail command. Required if you use sendmail transport
          sendmail = null;
          hostname = "mail.techsupporter.net";
          port = 587; # 465, If you use StartTLS: 587
          username = "no-reply@techsupporter.net";
          tls = false; # If you use StartTLS: false
          disable_starttls = false;
          ca_file = null; # Used for self signed certificates
          from_address = "no-reply@techsupporter.net";
        };
      };
      secrets.secretsFile = "/secrets/passwords/peertube/secret.txt";
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      enableTCPIP = true;
      port = 5432;
      dataDir = "/mnt/nfs/peertube/postgresql/${config.services.postgresql.package.psqlSchema}";
      ensureDatabases = [ "peertube" ];
      authentication = pkgs.lib.mkOverride 10 ''
        #type database DBuser origin-address auth-method
        local all      all                    trust
        # ipv4
        host  all      all     127.0.0.1/32   trust
        # ipv6
        host all       all     ::1/128        trust
      '';
      initialScript = pkgs.writeText "postgresql_init.sql" ''
        CREATE ROLE peertube LOGIN PASSWORD '${builtins.readFile "/secrets/passwords/postgresql/peertube.txt"}';
        CREATE DATABASE peertube TEMPLATE template0 ENCODING UTF8;
        GRANT ALL PRIVILEGES ON DATABASE peertube TO peertube;
        ALTER DATABASE peertube OWNER TO peertube;
        \connect peertube
        CREATE EXTENSION IF NOT EXISTS pg_trgm;
        CREATE EXTENSION IF NOT EXISTS unaccent;
      '';
    };

    redis.servers.peertube = {
      enable = true;
      bind = "0.0.0.0";
      requirePass = builtins.readFile "/secrets/passwords/redis/redis.txt";
      port = 31638;
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
