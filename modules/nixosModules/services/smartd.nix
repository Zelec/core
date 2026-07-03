{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-smartd];
  };
  flake.nixosModules.services-smartd = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.smartd;
  in {
    options.zelec-core.services.smartd = {
      enable = lib.mkEnableOption "Enables smartd";
    };
    config = lib.mkIf cfg.enable {
      services.smartd = {
        enable = true;
        autodetect = true;
      };
    };
  };
}
