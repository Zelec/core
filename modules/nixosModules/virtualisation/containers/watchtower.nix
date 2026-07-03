{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-containers-watchtower];
  };
  flake.nixosModules.virtualisation-containers-watchtower = {
    config,
    lib,
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
    };
    config = lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers."watchtower" = {
        image = "docker.io/nickfedor/watchtower:latest";
        environment = {
          "TZ" = cfg.timeZone;
          "WATCHTOWER_EPHEMERAL_SELF_UPDATE" = "true";
          "WATCHTOWER_LABEL_ENABLE" = "true";
          "WATCHTOWER_NOTIFICATIONS_HOSTNAME" = cfg.notificationIdentifier;
          "WATCHTOWER_ROLLING_RESTART" = "false";
          "WATCHTOWER_SCHEDULE" = cfg.schedule;
        };
        volumes = ["/var/run/docker.sock:/var/run/docker.sock"];
        log-driver = "journald";
        environmentFiles = [] ++ lib.optionals (cfg.envFilePath != null) cfg.envFilePath;
      };
      zelec-core.virtualisation.dockerManager.watchtower = {
        containerNames = [
          "watchtower"
        ];
      };
    };
  };
}
