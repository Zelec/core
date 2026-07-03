{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.hardware-bluetooth];
  };
  flake.nixosModules.hardware-bluetooth = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.hardware.bluetooth;
  in {
    options.zelec-core.hardware.bluetooth = {
      enable = lib.mkEnableOption "Enables bluetooth";
    };
    config = lib.mkIf cfg.enable {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
    };
  };
}
