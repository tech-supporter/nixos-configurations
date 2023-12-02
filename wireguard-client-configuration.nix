{ config, lib, pkgs, ... }:

{
  options.wireguard-client-configuration.ips = lib.mkOption
  {
    type = lib.types.listOf lib.types.str;
  };

  options.wireguard-client-configuration.port = lib.mkOption
  {
    type = lib.types.int;
  };

  options.wireguard-client-configuration.endpoint = lib.mkOption
  {
    type = lib.types.str;
  };

  options.wireguard-client-configuration.privateKeyFile = lib.mkOption
  {
    type = lib.types.str;
  };

  options.wireguard-client-configuration.peerPublicKey = lib.mkOption
  {
    type = lib.types.str;
  };

  options.wireguard-client-configuration.prefixLength = lib.mkOption
  {
    type = lib.types.int;
  };

  config.networking.firewall = {
    allowedUDPPorts = [ config.wireguard-client-configuration.port ];
  };

  config.networking.wireguard.interfaces = {
    wg0 = {
      ips = config.wireguard-client-configuration.ips;

      listenPort = config.wireguard-client-configuration.port;

      # setup routing so traffic goes through the vpn peer
      postSetup = ''
        ip route add ${config.wireguard-client-configuration.endpoint} via ${config.networking.defaultGateway.address} dev eth0

        # Mark packets on the wg0 interface
        wg set wg0 fwmark ${toString config.wireguard-client-configuration.port}

        # Forbid anything else which doesn't go through wireguard VPN on
        # ipV4 and ipV6
        ${pkgs.iptables}/bin/iptables -A OUTPUT \
          ! -d ${config.networking.defaultGateway.address}/${toString config.wireguard-client-configuration.prefixLength} \
          ! -o wg0 \
          -m mark ! --mark $(wg show wg0 fwmark) \
          -m addrtype ! --dst-type LOCAL \
          -j REJECT
        ${pkgs.iptables}/bin/ip6tables -A OUTPUT \
          ! -o wg0 \
          -m mark ! --mark $(wg show wg0 fwmark) \
          -m addrtype ! --dst-type LOCAL \
          -j REJECT
      '';

      # This undoes the above command
      postShutdown = ''
        ip route del ${toString config.wireguard-client-configuration.endpoint}

        ${pkgs.iptables}/bin/iptables -D OUTPUT \
          ! -o wg0 \
          -m mark ! --mark $(wg show wg0 fwmark) \
          -m addrtype ! --dst-type LOCAL \
          -j REJECT
        ${pkgs.iptables}/bin/ip6tables -D OUTPUT \
          ! -o wg0 -m mark \
          ! --mark $(wg show wg0 fwmark) \
          -m addrtype ! --dst-type LOCAL \
          -j REJECT
      '';

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      privateKeyFile = config.wireguard-client-configuration.privateKeyFile;

      peers = [
        {
          publicKey = config.wireguard-client-configuration.peerPublicKey;
          allowedIPs = [ "0.0.0.0/0" ];
          persistentKeepalive = 25;
          endpoint = "${config.wireguard-client-configuration.endpoint}:${toString config.wireguard-client-configuration.port}";
        }
      ];
    };
  };
}
