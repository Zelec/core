{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-obs];
  };
  flake.nixosModules.programs-obs = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.obs;
  in {
    options.zelec-core.programs.obs = {
      enable = lib.mkEnableOption "Enables neovim";
      enableCUDA = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
    config = lib.mkIf cfg.enable {
      programs.obs-studio = {
        enable = true;
        enableVirtualCamera = true;

        # optional Nvidia hardware acceleration
        package = (
          pkgs.obs-studio.override {
            cudaSupport = cfg.enableCUDA;
          }
        );

        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-backgroundremoval
          obs-pipewire-audio-capture
          obs-vaapi #optional AMD hardware acceleration
          obs-gstreamer
          obs-vkcapture
        ];
      };
    };
  };
}
