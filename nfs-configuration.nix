{ config, lib, pkgs, ... }:

{
  options.nfs-configuration.paths = lib.mkOption
  {
    type = lib.types.listOf lib.types.str;
  };

  options.nfs-configuration.storageUsers = lib.mkOption
  {
    type = lib.types.listOf lib.types.str;
  };

  config.fileSystems = builtins.listToAttrs (
    builtins.map (path:
      { 
        name = "/mnt/nfs/${path}";
        value =
        { 
          device = "storage.server.techsupporter.net:/srv/nfs/storage/vm/${path}";
          fsType = "nfs";
        };
      }
    ) 
    config.nfs-configuration.paths
  );

  # group needed for accessing data on the nfs share
  config.users.groups.vmstorage =
  {
    gid = 1011;
  };

  config.users.groups.vmstorage.members = config.nfs-configuration.storageUsers;
}
