{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.hardware-nvidia];
  };
  flake.nixosModules.hardware-nvidia = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.hardware.nvidia;
  in {
    options.zelec-core.hardware.nvidia = {
      enable = lib.mkEnableOption "Enables Nvidia settings";
      enablePatch = lib.mkEnableOption "Enables NVENC Patches";
      package = lib.mkOption {
        type = lib.types.package;
        default = config.boot.kernelPackages.nvidiaPackages.stable;
      };
      settings = {
        # Modesetting is required.
        modesetting.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        # NVidia power management, experimental, but needed due to firmware bugs
        powerManagement.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        # Fine-grained power management. Turns off GPU when not in use. super experimental, only applies to prime offloading setups
        powerManagement.finegrained = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        # Enables open kernel drivers (Breaks CUDA)
        open = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        # Enable the Nvidia settings menu,
        nvidiaSettings = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
    };
    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        hardware.graphics = {
          enable = true;
          enable32Bit = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 true;
        };
        environment.systemPackages = with pkgs; [
          cudaPackages.cudatoolkit
        ];
        # Load nvidia driver for Xorg and Wayland
        services.xserver.videoDrivers = ["nvidia"];
        hardware.nvidia = {
          modesetting.enable = cfg.settings.modesetting.enable;
          powerManagement.enable = cfg.settings.powerManagement.enable;
          powerManagement.finegrained = cfg.settings.powerManagement.finegrained;
          open = cfg.settings.open;
          nvidiaSettings = cfg.settings.nvidiaSettings;
        };
      }
      # If patch enabled, patch NVENC and FBC
      (lib.mkIf (cfg.enablePatch) {
        hardware.nvidia.package = pkgs.nvidia-patch.patch-nvenc (pkgs.nvidia-patch.patch-fbc cfg.package);
      })
      # If patch isn't enabled, use the chosen default nvidia package
      (lib.mkIf (! cfg.enablePatch) {
        hardware.nvidia.package = cfg.package;
      })
    ]);
  };
}
