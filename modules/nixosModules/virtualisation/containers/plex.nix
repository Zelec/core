{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-containers-plex];
  };
  flake.nixosModules.virtualisation-containers-plex = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.containers.plex;
  in {
    options.zelec-core.virtualisation.containers.plex = {
      enable = lib.mkEnableOption "Enables the plex container";
      appdata = lib.mkOption {
        type = lib.types.str;
        default = "/opt/dockerservices/plex";
      };
      media = lib.mkOption {
        type = lib.types.str;
        default = "/media/Storage_01/media";
      };
      timeZone = lib.mkOption {
        type = lib.types.str;
        default = cfgRoot.base.timeZone;
        example = "America/Toronto";
      };
    };
    config = lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers."plex" = {
        image = "lscr.io/linuxserver/plex:latest";
        environment = {
          "PUID" = "1000";
          "PGID" = "100";
          "TZ" = cfg.timeZone;
          "VERSION" = "public";
          "NVIDIA_VISIBLE_DEVICES" = "all";
          # "NVIDIA_DRIVER_CAPABILITIES" = "compute,video,utility";
        };
        volumes = [
          "${cfg.media}:/plex_media:rw"
          "${cfg.appdata}/config/plex:/config:rw"
          "${cfg.appdata}/tmp/transcode:/transcode:rw"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        log-driver = "journald";
        extraOptions = [
          "--device=nvidia.com/gpu=all"
          "--network=host"
        ];
      };
      virtualisation.oci-containers.containers."tautulli" = {
        image = "lscr.io/linuxserver/tautulli:latest";
        environment = {
          "PUID" = "1000";
          "PGID" = "100";
          "TZ" = cfg.timeZone;
        };
        volumes = [
          "${cfg.appdata}/config/tautulli:/config:rw"
        ];
        ports = [
          "8181:8181/tcp"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        log-driver = "journald";
        extraOptions = [
          "--network-alias=tautulli"
          "--network=plex_default"
        ];
      };
      zelec-core.virtualisation.dockerManager.plex = {
        containerNames = [
          "plex"
          "tautulli"
        ];
        networkNames = [
          "default"
        ];
      };
    };
  };
}
