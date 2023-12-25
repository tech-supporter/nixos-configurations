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
    ];

  config.server-configuration.address = "10.0.0.14";

  config.networking.hostName = "search";

  config.wireguard-client-configuration =
  {
    ips = ["10.65.116.27/32"];
    port = 51820;
    endpoint = "68.235.44.2";
    privateKeyFile = "/secrets/keys/wireguard/private/mullvad.key";
    peerPublicKey = "T5aabskeYCd5dn81c3jOKVxGWQSLwpqHSHf6wButSgw=";
    prefixLength = config.server-configuration.prefixLength;
  };

  config.networking.firewall.allowedTCPPorts = [ 8080 ];

  config.environment.systemPackages = [
    pkgs.searxng
  ];

  config.services.searx = {
    enable = true;
    settings = {
      server = {
        base_url = "https://search.techsupporter.net/";
        port = 8080;
        bind_address = "0.0.0.0";
        secret_key = builtins.readFile "/secrets/passwords/searx/server.txt";
      };
      ui = {
        default_theme = "simple";
        theme_args = {
          simple_style = "dark";
        };
      };
      engines = [
        {
          name = "startpage";
          engine = "startpage";
          disabled = false;
          timeout = 6.0;
          shortcut = "sp";
        }
      ];
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
