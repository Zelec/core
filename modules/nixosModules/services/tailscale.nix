{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-tailscale];
  };
  flake.nixosModules.services-tailscale = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.tailscale;
  in {
    options.zelec-core.services.tailscale = {
      enable = lib.mkEnableOption "Enables tailscale";
      subnetRouter = {
        enable = lib.mkEnableOption "Enables subnet router config and sets up BGP";
        localASN = lib.mkOption {
          type = lib.types.str;
          default = "65011";
        };
        remoteASN = lib.mkOption {
          type = lib.types.str;
          default = "65011";
        };
        bgpNeighbor = lib.mkOption {
          type = lib.types.str;
          default = "10.0.0.1";
        };
        advertisedRoutes = lib.mkOption {
          type = lib.types.str;
          default = "10.0.0.0/24";
        };
        enableExitNode = lib.mkEnableOption "Enables exit node setup";
      };
    };
    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        services.tailscale.enable = true;
      }
      # A bit of an experiment with bird and tailscale routes HA mode
      # https://tailscale.com/docs/features/subnet-routers/how-to/bgp
      (lib.mkIf (cfg.subnetRouter.enable) {
        services.tailscale = {
          useRoutingFeatures = "both";
          # Uses Bird to toggle and advertise the routes in HA mode
          extraDaemonFlags = ["--bird-socket=/var/run/bird/bird.ctl"];
          extraSetFlags = [
            "--snat-subnet-routes=false"
            "--advertise-routes=${cfg.subnetRouter.advertisedRoutes}"
            (lib.mkIf (cfg.subnetRouter.enableExitNode) "--advertise-exit-node=true")
          ];
        };
        # BGP Daemon compatible with Tailscale
        services.bird = {
          enable = true;
          config = ''
            log syslog all;

            protocol device {
              scan time 10;
            }

            protocol bgp {
              local as ${cfg.subnetRouter.localASN};
              neighbor ${cfg.subnetRouter.bgpNeighbor} as ${cfg.subnetRouter.remoteASN};
              ipv4 {
                import none;
                export all;
              };
            }
            protocol static tailscale {
              ipv4;
              route 100.64.0.0/10 via "${config.services.tailscale.interfaceName}";
            }
          '';
        };
      })
      (lib.mkIf (! cfg.subnetRouter.enable) {
        services.tailscale.useRoutingFeatures = "client";
      })
      (lib.mkIf (config.networking.firewall.enable) {
        networking.firewall.trustedInterfaces = ["tailscale0"];
      })
    ]);
  };
}
