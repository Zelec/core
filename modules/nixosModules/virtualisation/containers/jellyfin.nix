{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-containers-jellyfin];
  };
  flake.nixosModules.virtualisation-containers-jellyfin = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.containers.jellyfin;
    podmanEnabled = config.zelec-core.virtualisation.podman.enable or false;
    caddyNetwork = config.zelec-core.virtualisation.containers.caddy.dockerNetworkName;
  in {
    options.zelec-core.virtualisation.containers.jellyfin = {
      enable = lib.mkEnableOption "Enables the jellyfin container";
      url = lib.mkOption {
        type = lib.types.str;
        default = "jellyfin.timeguard.ca";
      };
      appdata = lib.mkOption {
        type = lib.types.str;
        default = "/opt/dockerservices/jellyfin";
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
            assertion = cfg.enable -> podmanEnabled;
            message = ''
              `zelec-core.virtualisation.containers.jellyfin` is enabled, but Podman is not active.
              Please enable `zelec-core.virtualisation.podman.enable`.
            '';
          }
        ];
        warnings = lib.optional (!cfgRoot.testing) ''
          The module `zelec-core.virtualisation.containers.jellyfin` is not fully done, if you
          want to hide this warning you'll need to set `zelec-core.testing` to true
        '';
      }
      (lib.mkIf cfg.enable {
        networking.firewall = {
          allowedUDPPorts = [
            # Client AutoDiscover
            7359
            # DLNA Discovery
            1900
          ];
        };
      })
      (lib.mkIf (cfg.enable && podmanEnabled) {
        systemd.tmpfiles.rules = [
          "d ${cfg.appdata} 0755 1000 100 - -"
          "d ${cfg.appdata}/config 0755 1000 100 - -"
          "d ${cfg.appdata}/config/jellyfin 0755 1000 100 - -"
        ];
        virtualisation.quadlet = {
          containers.quadlet-jellyfin = {
            containerConfig = {
              name = "jellyfin";
              image = "lscr.io/linuxserver/jellyfin:latest";
              autoUpdate = lib.mkIf config.zelec-core.virtualisation.podman.autoUpdate.enable "registry";
              environments = {
                PUID = "1000";
                PGID = "100";
                TZ = cfg.timeZone;
                NVIDIA_VISIBLE_DEVICES = "all";
                JELLYFIN_PublishedServerUrl = cfg.url;
              };
              volumes = [
                "${cfg.appdata}/config/jellyfin:/config:rw"
                "${cfg.media}/Music:/data/Music:rw"
              ];
              ports = [
                "7359:7359/udp"
                "1900:1900/udp"
              ];
              logDriver = "journald";
              networks = [
                "${caddyNetwork}.network"
              ];
              labels = {
                "caddy" = "${cfg.url}";
                "caddy.import" = "base_config";
                "caddy.reverse_proxy" = "{{upstreams 8096}}";
              };
              devices = ["/dev/dri:/dev/dri"] ++ lib.optionals config.zelec-core.virtualisation.podman.nvidia.enable ["nvidia.com/gpu=all"];
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
