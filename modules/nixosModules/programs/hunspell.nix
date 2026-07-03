{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-hunspell];
  };
  flake.nixosModules.programs-hunspell = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.hunspell;
  in {
    options.zelec-core.programs.hunspell = {
      enable = lib.mkEnableOption "Enables hunspell";
    };
    config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        (hunspell.withDicts (
          dict: [
            dict.en_CA-large
            dict.en_US-large
            dict.en_GB-large
          ]
        ))
      ];
    };
  };
}
