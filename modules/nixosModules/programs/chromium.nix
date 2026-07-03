{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-chromium];
  };
  flake.nixosModules.programs-chromium = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.chromium;
  in {
    options.zelec-core.programs.chromium = {
      enable = lib.mkEnableOption "Enables Chromium Browser";
    };
    config = lib.mkIf cfg.enable {
      home-manager.users.${config.zelec-core.base.user.name} = {
        programs.chromium = {
          enable = true;
          package = pkgs.chromium;
        };
      };
    };
  };
}
