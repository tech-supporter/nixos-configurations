{ config, pkgs, ... }:

{
  time.timeZone = "America/Chicago";

  # user groups and passwords must be set in the nix configuration
  users.mutableUsers = false;

  users.users.root = {
    passwordFile = "/secrets/passwords/root.txt";
  };

  users.users.techsupporter = {
    isNormalUser = true;
    extraGroups = [ "wheel" "power" "storage" ];
    passwordFile = "/secrets/passwords/techsupporter.txt";
    openssh.authorizedKeys.keyFiles = [
      "/secrets/keys/ssh/public/techsupporter.key"
    ];
  };

  environment.systemPackages = with pkgs; [
     vim
     git
  ];
}
