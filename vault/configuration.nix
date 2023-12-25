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

  config.server-configuration.address = "10.0.0.3";

  config.networking.hostName = "vault";
  config.networking.firewall.allowedTCPPorts = [ 80 ];

  config.nfs-configuration.paths = [ "vault" ];
  config.nfs-configuration.storageUsers = 
  [
    "vaultwarden"
    "postgres"
  ];

  config.users.users.vaultwarden.uid = 70;
  config.users.users.postgres.uid = 71;

  config.users.groups.vaultwarden.gid = 70;
  config.users.groups.postgres.gid = 71;

  config.environment.systemPackages = with pkgs; [
    vaultwarden-postgresql
    postgresql
  ];

  config.services.vaultwarden =
  {
    enable = true;
    dbBackend = "postgresql";
    config = 
    {
      DATA_FOLDER = "/mnt/nfs/vault/vaultwarden/data";
      DATABASE_URL = "postgresql://vaultwarden:${builtins.readFile "/secrets/passwords/postgresql/vaultwarden.txt"}@127.0.0.1:5432/vaultwarden";
      WEB_VAULT_ENABLED = true;

      DOMAIN = "https://password.techsupporter.net";

      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 80;  # Defaults to 80 in the Docker images, or 8000 otherwise.
      ROCKET_WORKERS = 10;
      #ROCKET_TLS={certs="/path/to/certs.pem",key="/path/to/key.pem"};

      SMTP_HOST = "mail.techsupporter.net";
      SMTP_FROM = "no-reply@techsupporter.net";
      SMTP_FROM_NAME = "VaultWarden";
      SMTP_SECURITY = "starttls"; # ("starttls", "force_tls", "off") Enable a secure connection. Default is "starttls" (Explicit - ports 587 or 25), "force_tls" (Implicit - port 465) or "off", no encryption (port 25)
      SMTP_PORT = 587;          # Ports 587 (submission) and 25 (smtp) are standard without encryption and with encryption via STARTTLS (Explicit TLS). Port 465 (submissions) is used for encrypted submission (Implicit TLS).
      SMTP_USERNAME = "no-reply@techsupporter.net";
      SMTP_PASSWORD = (builtins.readFile "/secrets/passwords/vaultwarden/email.txt");
      SMTP_TIMEOUT = 15;
    
      ADMIN_TOKEN = (builtins.readFile "/secrets/passwords/vaultwarden/admin.txt");
    };
  };

  config.services.postgresql = 
  {
    enable = true;

    package = pkgs.postgresql_15;

    enableTCPIP = true;
    port = 5432;

    dataDir = "/mnt/nfs/vault/postgresql/${config.services.postgresql.package.psqlSchema}";
    ensureDatabases = [ "vaultwarden" ];

    authentication = pkgs.lib.mkOverride 10 ''
      #type database DBuser origin-address auth-method
      local all      all                    trust
      # ipv4
      host  all      all     127.0.0.1/32   trust
      # ipv6
      host all       all     ::1/128        trust
    '';

    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE vaultwarden WITH LOGIN PASSWORD '${builtins.readFile "/secrets/passwords/postgresql/vaultwarden.txt"}' CREATEDB;
      CREATE DATABASE vaultwarden;
      GRANT ALL PRIVILEGES ON DATABASE vaultwarden TO vaultwarden;
      ALTER DATABASE vaultwarden OWNER TO vaultwarden;
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
