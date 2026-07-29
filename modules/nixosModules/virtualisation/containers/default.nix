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
    enabledSystem = (cfgRoot.virtualisation.docker.enable or false) || (cfgRoot.virtualisation.podman.enable or false);
  in {
    options.zelec-core.virtualisation.containers = {
      enableDefaultContainers = lib.mkOption {
        description = "Enables default containers in this stack";
        type = lib.types.bool;
        default = enabledSystem;
      };
    };
  };
}
