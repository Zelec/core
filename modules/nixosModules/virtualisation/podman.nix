{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-podman];
  };
  flake.nixosModules.virtualisation-podman = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.podman;
    dockerEnabled = config.zelec-core.virtualisation.docker.enable or false;
  in {
    imports = [
      inputs.quadlet-nix.nixosModules.quadlet
    ];
    options.zelec-core.virtualisation.podman = {
      enable = lib.mkEnableOption "Enables Podman and Quadlet support";
      autoUpdate = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automatic daily container updates via Podman auto-update";
        };
        schedule = lib.mkOption {
          type = lib.types.str;
          default = "02:00"; # Runs daily at 2:00 AM
          example = "Sun *-*-* 03:00:00"; # Weekly on Sunday at 3:00 AM
          description = "systemd OnCalendar expression defining when auto-updates trigger";
        };
      };
      storageDriver = lib.mkOption {
        type = lib.types.str;
        default = "btrfs";
        description = "Storage driver used by Podman backend";
      };
      nvidia.enable = lib.mkEnableOption "Enables NVIDIA support in Podman";
    };
    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.enable -> !dockerEnabled;
            message = ''
              Conflict detected in `zelec-core`:
              `zelec-core.virtualisation.docker.enable` cannot be `true` when using the Podman module.
              Please remove or set `zelec-core.virtualisation.docker.enable = false;`.
            '';
          }
        ];
      }
      (
        lib.mkIf cfg.enable
        {
          users.users.${config.zelec-core.base.user.name}.extraGroups = ["podman"];
          # Yes I know, I really should not do this
          # I probably need some time yet to get fully off the docker way of working & thinking
          environment.sessionVariables = {
            CONTAINER_HOST = "unix:///run/podman/podman.sock";
          };
          virtualisation = {
            containers.enable = true;
            oci-containers.backend = "podman";
            podman = {
              enable = true;
              autoPrune = {
                enable = true;
                dates = "weekly";
              };
              dockerCompat = true;
              dockerSocket.enable = true;
              defaultNetwork.settings.dns_enabled = true;
            };
            quadlet = {
              enable = true;
              autoUpdate.enable = cfg.autoUpdate.enable;
              autoUpdate.calendar = cfg.autoUpdate.schedule;
            };
            containers.storage.settings = {
              storage = {
                driver = cfg.storageDriver;
              };
            };
          };
          # NVIDIA / CDI Configuration for Podman
          hardware.nvidia-container-toolkit = lib.mkIf cfg.nvidia.enable {
            enable = true;
            mount-nvidia-executables = true;
            mount-nvidia-docker-1-directories = true;
            device-name-strategy = "index";
          };
          # Firewall configuration for Podman interfaces
          networking.firewall.trustedInterfaces = lib.mkIf config.networking.firewall.enable [
            "podman0"
            "br-+"
          ];
        }
      )
    ];
  };
}
