{ config, lib, pkgs, ... }:

{
  options.nfs-configuration.path = lib.mkOption
  {
    type = lib.types.str;
  };

  options.nfs-configuration.storageUsers = lib.mkOption
  {
    type = lib.types.listOf lib.types.str;
  };

  config.fileSystems."/mnt/nfs" = {
    device = "storage.server.techsupporter.net:/srv/nfs/storage/vm/${config.nfs-configuration.path}";
    fsType = "nfs";
  };

  # group needed for accessing data on the nfs share
  config.users.groups.vmstorage =
  {
    gid = 1011;
  };

  config.users.groups.vmstorage.members = config.nfs-configuration.storageUsers;
}
