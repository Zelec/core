{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-containers-watchtower];
  };
  flake.nixosModules.virtualisation-containers-watchtower = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.containers.watchtower;
  in {
    options.zelec-core.virtualisation.containers.watchtower = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfgRoot.virtualisation.containers.enableDefaultContainers;
        example = true;
      };
      envFilePath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      schedule = lib.mkOption {
        type = lib.types.str;
        default = "0 0 2 * * *";
      };
      timeZone = lib.mkOption {
        type = lib.types.str;
        default = config.zelec-core.base.timeZone;
      };
      notificationIdentifier = lib.mkOption {
        type = lib.types.str;
        default = "${config.networking.hostName}";
      };
      # Allows the watchtower container itself to update itself
      containerUpdates = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg.enable;
          example = true;
        };
        schedule = lib.mkOption {
          type = lib.types.str;
          default = "0 0 6 * * *";
        };
      };
    };
    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        virtualisation.oci-containers.containers."watchtower" = {
          image = "ghcr.io/nicholas-fedor/watchtower:latest";
          environment = {
            "TZ" = cfg.timeZone;
            "WATCHTOWER_LABEL_ENABLE" = "true";
            "WATCHTOWER_NOTIFICATIONS_HOSTNAME" = cfg.notificationIdentifier;
            "WATCHTOWER_ROLLING_RESTART" = "false";
            "WATCHTOWER_SCHEDULE" = cfg.schedule;
          };
          volumes = ["/var/run/docker.sock:/var/run/docker.sock"];
          log-driver = "journald";
          environmentFiles = [] ++ lib.optionals (cfg.envFilePath != null) [cfg.envFilePath];
        };
        zelec-core.virtualisation.dockerManager.watchtower = {
          containerNames = [
            "watchtower"
          ];
        };
      }
      (lib.mkIf cfg.containerUpdates.enable {
        # Watchtower doesn't end up updating itself, need to provide an out of band updater for it
        systemd.services."docker-watchtower-self-updater" = {
          description = "Pull latest Watchtower image and restart container if updated";
          after = ["docker.service"];
          requires = ["docker.service"];
          script = ''
            IMAGE="${config.virtualisation.oci-containers.containers."watchtower".image}"
            DOCKER="${pkgs.docker}/bin/docker"
            
            echo "Checking for updates to $IMAGE..."
            
            OLD_SHA=$($DOCKER images -q "$IMAGE" 2>/dev/null || true)

            $DOCKER pull "$IMAGE"

            NEW_SHA=$($DOCKER images -q "$IMAGE")
            
            if [ "$OLD_SHA" = "$NEW_SHA" ] && [ -n "$OLD_SHA" ]; then
              echo "Watchtower is already on the latest image ($OLD_SHA). Exiting."
            else
              echo "New Watchtower image detected ($NEW_SHA)! Restarting docker-watchtower service..."
              ${pkgs.systemd}/bin/systemctl restart docker-watchtower.service
            fi
          '';
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
        };
        systemd.timers."docker-watchtower-self-updater" = {
          description = "Timer for Watchtower self-updater";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = cfg.containerUpdates.schedule;
            Persistent = true;
          };
        };
      })
    ]);
  };
}
