{ config, pkgs, ... }:

{
  networking.firewall.enable = true;
  #networking.networkmanager.enable = true;

  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "10.0.0.2" ]; # "9.9.9.9" "149.112.112.112"
}
