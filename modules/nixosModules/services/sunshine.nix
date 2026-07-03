{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-sunshine];
  };
  flake.nixosModules.services-sunshine = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.sunshine;
  in {
    options.zelec-core.services.sunshine = {
      enable = lib.mkEnableOption "Enables sunshine";
      enableCUDA = lib.mkEnableOption "Enables cuda support";
    };
    config = lib.mkIf cfg.enable {
      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
        package = pkgs.sunshine.override {
          # Enables NVENC support
          # Obsolete workaround now that everything is merged in
          # https://github.com/NixOS/nixpkgs/issues/305891#issuecomment-2448635163
          # All that is needed to get it working now
          # https://github.com/NixOS/nixpkgs/issues/305891#issuecomment-3707474398
          cudaSupport = cfg.enableCUDA;
          cudaPackages = pkgs.cudaPackages;
        };
      };
      services.avahi.publish = {
        enable = true;
        userServices = true;
      };
    };
  };
}
