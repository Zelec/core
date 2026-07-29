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
    podmanEnabled = config.zelec-core.virtualisation.podman.enable or false;
  in {
    options.zelec-core.virtualisation.docker = {
      enable = lib.mkEnableOption "Enables docker";
      storageDriver = lib.mkOption {
        type = lib.types.str;
        default = "btrfs";
      };
      nvidia.enable = lib.mkEnableOption "Enables NVIDIA in Docker";
    };
    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.enable -> !podmanEnabled;
            message = ''
              Conflict detected in `zelec-core`:
              `zelec-core.virtualisation.podman.enable` cannot be `true` when `zelec-core.virtualisation.docker.enable` is `true`.
              Please set `zelec-core.virtualisation.podman.enable = false;`.
            '';
          }
        ];
      }
      (lib.mkIf cfg.enable {
        users.users.${config.zelec-core.base.user.name}.extraGroups = ["docker"];
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
        # NVIDIA / CDI Configuration
        environment.systemPackages = lib.mkIf cfg.nvidia.enable [
          pkgs.nvidia-container-toolkit
        ];
        hardware.nvidia-container-toolkit = lib.mkIf cfg.nvidia.enable {
          enable = true;
          mount-nvidia-executables = true;
          mount-nvidia-docker-1-directories = true;
          device-name-strategy = "index";
        };
        virtualisation.docker.daemon.settings = lib.mkIf cfg.nvidia.enable {
          features.cdi = true;
        };
        # Firewall configuration for Docker interfaces
        networking.firewall.trustedInterfaces = lib.mkIf config.networking.firewall.enable [
          "docker0"
          "br-+"
        ];
      })
    ];
  };
}
