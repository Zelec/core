{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-printing];
  };
  flake.nixosModules.services-printing = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.printing;
  in {
    options.zelec-core.services.printing = {
      enable = lib.mkEnableOption "Enables printing";
    };
    config = lib.mkIf cfg.enable {
      services.printing = {
        enable = true;
        drivers = with pkgs; [
          brlaser
          epson-escpr
          epson-escpr2
          gutenprint
          gutenprintBin
          hplip
          mfcl3770cdwlpr
          splix
        ];
      };
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };
  };
}
