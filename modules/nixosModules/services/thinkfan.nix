{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-thinkfan];
  };
  flake.nixosModules.services-thinkfan = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.thinkfan;
  in {
    options.zelec-core.services.thinkfan = {
      enable = lib.mkEnableOption "Enables thinkfan";
    };
    config = lib.mkIf cfg.enable {
      services.thinkfan = {
        enable = true;
        smartSupport = true;
        levels = [
          [
            0
            0
            55
          ]
          [
            1
            48
            60
          ]
          [
            2
            50
            61
          ]
          [
            3
            52
            63
          ]
          [
            6
            56
            65
          ]
          [
            7
            60
            85
          ]
          [
            "level full-speed"
            80
            32767
          ]
        ];
      };
    };
  };
}
