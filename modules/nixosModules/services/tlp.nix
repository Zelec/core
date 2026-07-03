# I probably should replace this with power-profiles-daemon
# but it has no good way of being declarative, or atleast pre-setup to allow tweaks afterwards
# atleast with this I can pre-bake battery charge leveling on all of my laptops, and configure other
# power settings on a per system basis like I have on Aion
{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-tlp];
  };
  flake.nixosModules.services-tlp = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.tlp;
  in {
    options.zelec-core.services.tlp = {
      enable = lib.mkEnableOption "Enables tlp";
      cpuScaleGovAC = lib.mkOption {
        type = lib.types.str;
        default = "performance";
      };
      cpuScaleGovBAT = lib.mkOption {
        type = lib.types.str;
        default = "powersave";
      };
      cpuEnergyPerfAC = lib.mkOption {
        type = lib.types.str;
        default = "performance";
      };
      cpuEnergyPerfBAT = lib.mkOption {
        type = lib.types.str;
        default = "power";
      };
      cpuMinPerfAC = lib.mkOption {
        type = lib.types.int;
        default = 0;
      };
      cpuMaxPerfAC = lib.mkOption {
        type = lib.types.int;
        default = 100;
      };
      cpuMinPerfBAT = lib.mkOption {
        type = lib.types.int;
        default = 0;
      };
      cpuMaxPerfBAT = lib.mkOption {
        type = lib.types.int;
        default = 80;
      };
      batChargeThreshStart = lib.mkOption {
        type = lib.types.int;
        default = 75;
      };
      batChargeThreshStop = lib.mkOption {
        type = lib.types.int;
        default = 80;
      };
    };
    config = lib.mkIf cfg.enable {
      services.power-profiles-daemon.enable = false;
      services.tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = cfg.cpuScaleGovAC;
          CPU_SCALING_GOVERNOR_ON_BAT = cfg.cpuScaleGovBAT;

          CPU_ENERGY_PERF_POLICY_ON_AC = cfg.cpuEnergyPerfAC;
          CPU_ENERGY_PERF_POLICY_ON_BAT = cfg.cpuEnergyPerfBAT;

          CPU_MIN_PERF_ON_AC = cfg.cpuMinPerfAC;
          CPU_MAX_PERF_ON_AC = cfg.cpuMaxPerfAC;
          CPU_MIN_PERF_ON_BAT = cfg.cpuMinPerfBAT;
          CPU_MAX_PERF_ON_BAT = cfg.cpuMaxPerfBAT;

          #Optional helps save long term battery health
          START_CHARGE_THRESH_BAT0 = cfg.batChargeThreshStart;
          STOP_CHARGE_THRESH_BAT0 = cfg.batChargeThreshStop;
        };
      };
    };
  };
}
