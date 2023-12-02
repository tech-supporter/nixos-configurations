{ config, pkgs, ... }:

{
  time.timeZone = "America/Chicago";

  # user groups and passwords must be set in the nix configuration
  users.mutableUsers = false;

  users.users.root = {
    hashedPasswordFile = "/secrets/passwords/root.txt";
  };

  users.users.techsupporter = {
    isNormalUser = true;
    extraGroups = [ "wheel" "power" "storage" ];
    hashedPasswordFile = "/secrets/passwords/techsupporter.txt";
    openssh.authorizedKeys.keyFiles = [
      "/secrets/keys/ssh/public/techsupporter.key"
    ];
  };

  environment.systemPackages = with pkgs; [
     vim
     git
  ];
}
