{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.security-tpm2];
  };
  flake.nixosModules.security-tpm2 = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.security.tpm2;
  in {
    options.zelec-core.security.tpm2 = {
      enable = lib.mkEnableOption "Enables TPM2";
    };
    config = lib.mkIf cfg.enable {
      security = {
        tpm2 = {
          enable = true;
          abrmd.enable = true;
          pkcs11.enable = true;
          tctiEnvironment.enable = true;
          tctiEnvironment.interface = "tabrmd";
        };
      };
    };
  };
}
