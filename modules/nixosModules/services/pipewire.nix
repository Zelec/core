{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-pipewire];
  };
  flake.nixosModules.services-pipewire = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.pipewire;
  in {
    options.zelec-core.services.pipewire = {
      enable = lib.mkEnableOption "Enables pipewire";
    };
    config = lib.mkIf cfg.enable {
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber = {
          enable = true;
        };
      };
    };
  };
}
