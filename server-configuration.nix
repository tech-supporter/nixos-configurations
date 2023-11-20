{ config, lib, pkgs, ... }:

{
  options.server-configuration.address = lib.mkOption
  {
    type = lib.types.str;
  };

  config.networking.interfaces.eth0.ipv4.addresses =
  [
    {
      address = config.server-configuration.address;
      prefixLength = 8;
    }
  ];

  config.environment.systemPackages = with pkgs;
  [
     openssh
  ];

  config.services.openssh =
  {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  config.networking.useDHCP = false;
}
