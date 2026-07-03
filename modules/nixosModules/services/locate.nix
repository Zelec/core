# This module sucks (By that I mean I forget I have this installed on all of my machines
# and I fallback to using good ol `find / | grep 'whatever-im-looking-for`), I should probably get rid of it
# since it causes problems for the systemd automount points for my backup system.
{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-locate];
  };
  flake.nixosModules.services-locate = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.locate;
  in {
    options.zelec-core.services.locate = {
      enable = lib.mkEnableOption "Enables locate";
      interval = lib.mkOption {
        type = lib.types.str;
        default = "hourly";
      };
    };
    config = lib.mkIf cfg.enable {
      services.locate = {
        enable = true;
        package = pkgs.plocate;
        interval = cfg.interval;
        pruneFS = lib.mkOptionDefault [
          "fuse.gocryptfs"
        ];
        prunePaths = lib.mkOptionDefault [
          "/media/btrfsroots"
          "/media/secureArchiveStorage"
        ];
      };
    };
  };
}
