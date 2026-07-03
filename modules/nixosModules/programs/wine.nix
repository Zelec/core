{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-wine];
  };
  flake.nixosModules.programs-wine = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.wine;
  in {
    options.zelec-core.programs.wine = {
      enable = lib.mkEnableOption "Enables wine";
    };
    config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        wineWow64Packages.stableFull
        winetricks
      ];
    };
  };
}
