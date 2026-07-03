{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-btrfs-scrub];
  };
  flake.nixosModules.services-btrfs-scrub = {
    config,
    options,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.btrfs-scrub;
  in {
    options.zelec-core.services.btrfs-scrub = {
      enable = lib.mkEnableOption "Enables BTRFS weekly autoscrub";
      filesystems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["/"];
      };
    };
    config = lib.mkIf cfg.enable {
      services.btrfs.autoScrub = {
        enable = true;
        interval = "weekly";
        fileSystems = cfg.filesystems;
      };
    };
  };
}
