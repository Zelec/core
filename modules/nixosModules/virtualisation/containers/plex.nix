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
    dockerEnabled = config.zelec-core.virtualisation.docker.enable or false;
    podmanEnabled = config.zelec-core.virtualisation.podman.enable or false;
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
    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.enable -> (dockerEnabled || podmanEnabled);
            message = ''
              `zelec-core.virtualisation.containers.plex` is enabled, but neither Docker nor Podman is active.
              Please enable `zelec-core.virtualisation.docker.enable` or `zelec-core.virtualisation.podman.enable`.
            '';
          }
        ];
      }
      (lib.mkIf (cfg.enable && dockerEnabled) {
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
          extraOptions =
            [
              "--network=host"
            ]
            ++ lib.optionals config.zelec-core.virtualisation.docker.nvidia.enable ["--device=nvidia.com/gpu=all"];
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
      })
      (lib.mkIf (cfg.enable && podmanEnabled) {
        systemd.tmpfiles.rules = [
          "d ${cfg.appdata} 0755 1000 100 - -"
          "d ${cfg.appdata}/config 0755 1000 100 - -"
          "d ${cfg.appdata}/config/plex 0755 1000 100 - -"
          "d ${cfg.appdata}/config/tautulli 0755 1000 100 - -"
          "d ${cfg.appdata}/tmp 0755 1000 100 - -"
          "d ${cfg.appdata}/tmp/transcode 0755 1000 100 - -"
        ];
        virtualisation.quadlet = {
          networks.plex_default = {
            networkConfig = {
              driver = "bridge";
            };
          };
          containers.quadlet-plex = {
            containerConfig = {
              name = "plex";
              image = "lscr.io/linuxserver/plex:latest";
              autoUpdate = lib.mkIf config.zelec-core.virtualisation.podman.autoUpdate.enable "registry";
              environments = {
                PUID = "1000";
                PGID = "100";
                TZ = cfg.timeZone;
                VERSION = "public";
                NVIDIA_VISIBLE_DEVICES = "all";
              };
              volumes = [
                "${cfg.media}:/plex_media:rw"
                "${cfg.appdata}/config/plex:/config:rw"
                "${cfg.appdata}/tmp/transcode:/transcode:rw"
              ];
              logDriver = "journald";
              networks = ["host"];
              devices = lib.optionals config.zelec-core.virtualisation.podman.nvidia.enable ["nvidia.com/gpu=all"];
            };
            serviceConfig = {
              Restart = "always";
            };
          };
          containers.quadlet-tautulli = {
            containerConfig = {
              name = "tautulli";
              image = "lscr.io/linuxserver/tautulli:latest";
              autoUpdate = lib.mkIf config.zelec-core.virtualisation.podman.autoUpdate.enable "registry";
              environments = {
                PUID = "1000";
                PGID = "100";
                TZ = cfg.timeZone;
              };
              volumes = [
                "${cfg.appdata}/config/tautulli:/config:rw"
              ];
              publishPorts = [
                "8181:8181/tcp"
              ];
              logDriver = "journald";
              networks = ["plex_default.network"];
              networkAliases = ["tautulli"];
            };
            serviceConfig = {
              Restart = "always";
            };
          };
        };
      })
    ];
  };
}
