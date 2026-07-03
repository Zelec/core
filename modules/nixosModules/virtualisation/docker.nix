{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-docker];
  };
  flake.nixosModules.virtualisation-docker = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.docker;
  in {
    options.zelec-core.virtualisation.docker = {
      enable = lib.mkEnableOption "Enables docker";
      storageDriver = lib.mkOption {
        type = lib.types.str;
        default = "btrfs";
      };
      nvidia.enable = lib.mkEnableOption "Enables NVIDIA in Docker";
    };
    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        virtualisation = {
          containers.enable = true;
          oci-containers.backend = "docker";
          docker = {
            enable = true;
            autoPrune = {
              enable = true;
              dates = "weekly";
            };
            liveRestore = false;
            storageDriver = cfg.storageDriver;
          };
        };
      }
      (lib.mkIf (cfg.nvidia.enable) {
        environment.systemPackages = with pkgs; [
          nvidia-container-toolkit
        ];
        hardware.nvidia-container-toolkit = {
          enable = true;
          mount-nvidia-executables = true;
          mount-nvidia-docker-1-directories = true;
          device-name-strategy = "index";
        };
        virtualisation = {
          docker = {
            daemon.settings = {
              features.cdi = true;
              # default-runtime =  "nvidia";
              # runtimes.nvidia.path =  "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
              # exec-opts = ["native.cgroupdriver=cgroupfs"];
            };
          };
        };
      })
      (lib.mkIf (config.networking.firewall.enable) {
        networking.firewall.trustedInterfaces = ["docker0" "br-+"];
      })
    ]);
  };
}
