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

  config.server-configuration.address = "10.0.0.12";

  config.networking.hostName = "cloud";

  config.nfs-configuration.paths =
  [
    "cloud"
  ];

  config.nfs-configuration.storageUsers = 
  [ 
    "nextcloud"
    "postgres"
  ];

  config.users.users.postgres.uid = 71;
  config.users.groups.postgres.gid = 71;

  config.users.users.nextcloud.uid = 74;
  config.users.groups.nextcloud.gid = 74;

  config.networking.firewall.allowedTCPPorts = [ 80 ];

  config.environment.systemPackages = with pkgs; [
    postgresql
  ];

  config.systemd.services.nextcloud.unitConfig = {
    RequiresMountsFor = "/mnt/nfs/cloud/nextcloud /mnt/nfs/cloud/postgresql";
  };

  config.services.nextcloud =
  {
    enable = true;
    package = pkgs.nextcloud27;
    hostName = "cloud.techsupporter.net";
    home = "/mnt/nfs/cloud/nextcloud";
    datadir = "/mnt/nfs/cloud/nextcloud/data";
    maxUploadSize = "1G";
    database.createLocally = false;
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbname = "nextcloud";
      dbpassFile = "/secrets/passwords/postgresql/nextcloud.txt";
      dbhost = "localhost";
      dbport = 5432;
      adminuser = "root";
      adminpassFile = "/secrets/passwords/nextcloud/root.txt";
      overwriteProtocol = "https";
      trustedProxies = [ "10.0.0.8" ];
      extraTrustedDomains = [ "cloud.server.techsupporter.net" ];
    };
    extraOptions = {
      mail_from_address = "no-reply";
      mail_smtpmode = "smtp";
      mail_sendmailmode = "smtp";
      mail_domain = "techsupporter.net";
      mail_smtphost = "mail.techsupporter.net";
      mail_smtpauth = 1;
      mail_smtpport = 587;
      mail_smtpname = "no-reply@techsupporter.net";
      mail_smtppassword = (builtins.readFile "/secrets/passwords/nextcloud/email.txt");
    };
    extraApps = with config.services.nextcloud.package.packages.apps; {
      inherit news contacts calendar tasks;
    };
    extraAppsEnable = true;
  };

  config.services.postgresql =
  {
    enable = true;

    package = pkgs.postgresql_15;

    enableTCPIP = true;
    port = 5432;

    dataDir = "/mnt/nfs/cloud/postgresql/${config.services.postgresql.package.psqlSchema}";
    ensureDatabases = [ "nextcloud" ];

    authentication = pkgs.lib.mkOverride 10 ''
      #type database DBuser origin-address auth-method
      local all      all                    trust
      # ipv4
      host  all      all     127.0.0.1/32   trust
      # ipv6
      host all       all     ::1/128        trust
    '';

    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE nextcloud WITH LOGIN PASSWORD '${builtins.readFile "/secrets/passwords/postgresql/nextcloud.txt"}' CREATEDB;
      CREATE DATABASE nextcloud;
      GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
      ALTER DATABASE nextcloud OWNER TO nextcloud;
    '';
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
