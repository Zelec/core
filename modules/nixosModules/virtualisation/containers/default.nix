{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-containers];
  };
  flake.nixosModules.virtualisation-containers = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.containers;
  in {
    options.zelec-core.virtualisation.containers = {
      enableDefaultContainers = lib.mkOption {
        description = "Enables default containers in this stack";
        type = lib.types.bool;
        default = cfgRoot.autoEnable;
      };
    };
  };
}
