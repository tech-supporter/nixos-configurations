{ config, lib, pkgs, ... }:

{
  options.nfs-configuration.path = lib.mkOption
  {
    type = lib.types.str;
  };

  config.fileSystems."/mnt/nfs" = {
    device = "storage.server.techsupporter.net:/srv/nfs/storage/vm/${config.nfs-configuration.path}";
    fsType = "nfs";
  };
}
