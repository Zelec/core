{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-openssh];
  };
  flake.nixosModules.services-openssh = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.openssh;
  in {
    options.zelec-core.services.openssh = {
      enable = lib.mkEnableOption "Enables openssh";
    };
    config = lib.mkIf cfg.enable {
      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        settings.PermitRootLogin = "prohibit-password";
      };
    };
  };
}
