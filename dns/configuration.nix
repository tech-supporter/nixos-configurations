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
    ];

  server-configuration.address = "10.0.0.2";

  networking.hostName = "dns";

  environment.systemPackages = with pkgs; [
     adguardhome
     ddclient
  ];

  # Wait until dns is actually working, configuration is broken though so using another service to work around this
  # I beleive the issue is similar to this one:
  # https://github.com/NixOS/nixpkgs/issues/232799
  #systemd.services."ddclient".preStart =  [ "until host dns.techsupporter.net; do sleep 1; done;" ];

  systemd.services.dnsready = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'until ${pkgs.host}/bin/host dynamicdns.park-your-domain.com; do sleep 1; done'";
    };
  };

  systemd.services.ddclient.after = [ "dnsready.service" ];

  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings = {
      users = [
        {
          name = "techsupporter";
          # not a fan of this approach but there's no passwordFile option so this is about all I can do right now
          password = (builtins.readFile "/secrets/passwords/adguardhome/techsupporter.txt");
        }
      ];

      dns = {
        bind_host = "0.0.0.0";
        bind_port = 53;
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "149.112.112.112"
        ];
        rewrites = [
          { domain = "router.server.techsupporter.net"; answer = "10.0.0.1"; }
          { domain = "dns.server.techsupporter.net"; answer = "10.0.0.2"; }
          { domain = "password.server.techsupporter.net"; answer = "10.0.0.3"; }
          { domain = "movies.server.techsupporter.net"; answer = "10.0.0.4"; }
          { domain = "shows.server.techsupporter.net"; answer = "10.0.0.4"; }
          { domain = "jackett.server.techsupporter.net"; answer = "10.0.0.4"; }
          { domain = "torrent.server.techsupporter.net"; answer = "10.0.0.4"; }
          { domain = "3dprinter.server.techsupporter.net"; answer = "10.0.0.5"; }
          { domain = "printer.server.techsupporter.net"; answer = "10.0.0.6"; }
          { domain = "piped.server.techsupporter.net"; answer = "10.0.0.7"; }
          { domain = "media.server.techsupporter.net"; answer = "10.0.0.7"; }
          { domain = "*.techsupporter.net"; answer = "10.0.0.8"; }
          { domain = "storage.server.techsupporter.net"; answer = "10.0.0.10"; }
          { domain = "switch.server.techsupporter.net"; answer = "10.0.0.11"; }
          { domain = "cloud.server.techsupporter.net"; answer = "10.0.0.12"; }
          { domain = "vpn.server.techsupporter.net"; answer = "10.0.0.13"; }
          { domain = "search.server.techsupporter.net"; answer = "10.0.0.14"; }
          { domain = "dashboard.server.techsupporter.net"; answer = "10.0.0.14"; }
          { domain = "backup.server.techsupporter.net"; answer = "backup.server.techsupporter.net"; }
          { domain = "vpn.techsupporter.net"; answer = "vpn.techsupporter.net"; }
          { domain = "mail.techsupporter.net"; answer = "mail.techsupporter.net"; }
        ];
      };

      statistics = {
        ignored = [];
        interval = "2160h";
        enabled = true;
      };

      filters = [
        {
          enabled = true;
          name = "AdGuard DNS filter";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          id = 1;
        }
        {
          enabled = true;
          name = "AdAway Default Blocklist";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          id = 2;
        }
        {
          enabled = true;
          name = "The Big List of Hacked Malware Web Sites";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt";
          id = 1699461341;
        }
        {
          enabled = true;
          name = "Phishing URL Blocklist (PhishTank and OpenPhish)";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt";
          id = 1699461342;
        }
        {
          enabled = true;
          name = "Dandelion Sprout's Anti-Malware List";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt";
          id = 1699461343;
        }
        {
          enabled = true;
          name = "Malicious URL Blocklist (URLHaus)";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt";
          id = 1699461344;
        }
        {
          enabled = true;
          name = "NoCoin Filter List";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt";
          id = 1699461345;
        }
        {
          enabled = true;
          name = "Scam Blocklist by DurableNapkin";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt";
          id = 1699461346;
        }
        {
          enabled = true;
          name = "Stalkerware Indicators List";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_31.txt";
          id = 1699461347;
        }
      ];

      filtering = {
        blocking_ipv4 = "";
        blocking_ipv6 = "";
        blocked_services = {
          schedule = {
            time_zone = "Local";
          };
          ids = [];    
        };
        protection_disabled_until = null;
        safe_search = {
          enabled = false;
          bing = true;
          duckduckgo = true;
          google = true;
          pixabay = true;
          yandex = true;
          youtube = true;
        };
        blocking_mode = "default";
        parental_block_host = "family-block.dns.adguard.com";
        safebrowsing_block_host = "standard-block.dns.adguard.com";
        safebrowsing_cache_size = 1048576;
        safesearch_cache_size = 1048576;
        parental_cache_size = 1048576;
        cache_time = 30;
        filters_update_interval = 24;
        blocked_response_ttl = 10;
        filtering_enabled = true;
        parental_enabled = false;
        safebrowsing_enabled = false;
        protection_enabled = true;
      };
    };
  };

  services.ddclient = {
	enable = true;
        ssl = true;

        # cofigured for the status page of the DD-WRT router, hope I remeber this if/when I change routers...
        # also, it's going through the reverse proxy, so that needs to be working
        use="web, web=https://router.techsupporter.net/, web-skip='wan_ipaddr'";

        protocol = "namecheap";
        server = "dynamicdns.park-your-domain.com";
        domains = [ "vpn.techsupporter.net" "ns1.acme.techsupporter.net" ];
        username = "techsupporter.net";
        verbose = true;
        interval = "15min";     

        passwordFile = "/secrets/passwords/ddclient/namecheap.txt";
  };


  networking.firewall.allowedTCPPorts = [ 3000 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

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
  system.stateVersion = "23.11"; # Did you read the comment?
}
