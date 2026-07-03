# System tweaks/tunables
{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.base-system-tweaks = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.system-tweaks;
  in {
    options.zelec-core.system-tweaks = {
      enable = lib.mkOption {
        description = "Enables system tunables (systemd-oomd, sysctl swappiness, etc)";
        type = lib.types.bool;
        default = cfgRoot.autoEnable;
      };
      sysctl = {
        vm-swappiness = lib.mkOption {
          type = lib.types.ints.positive;
          default = 60;
        };
      };
      systemd = {
        oomd-enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
    };
    config = lib.mkIf cfg.enable {
      boot.kernel.sysctl = {
        "vm.swappiness" = cfg.sysctl.vm-swappiness;
      };
      systemd.oomd = {
        enable = cfg.systemd.oomd-enable;
        enableRootSlice = true;
        enableSystemSlice = true;
        enableUserSlices = true;
        settings.OOM = {
          DefaultMemoryPressureDurationSec = "20s";
        };
      };
      systemd.slices."user".sliceConfig = {
        ManagedOOMMemoryPressureLimit = "90%";
      };
    };
  };
}
