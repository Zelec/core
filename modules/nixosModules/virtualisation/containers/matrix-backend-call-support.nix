{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-containers-matrix-backend-call-support];
  };
  flake.nixosModules.virtualisation-containers-matrix-backend-call-support = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.containers.matrix-backend-call-support;
  in {
    options.zelec-core.virtualisation.containers.matrix-backend-call-support = {
      enable = lib.mkEnableOption "Enables matrix backend livekit container stack";
      contactUser = lib.mkOption {
        type = lib.types.str;
        default = "zelec";
      };
      config = {
        livekitJWTEnvPath = lib.mkOption {
          description = "Path to the livekit jwt service's env file to map into docker";
          type = lib.types.str;
        };
        livekitPath = lib.mkOption {
          description = "Path to the livekit config";
          type = lib.types.str;
        };
        coturnPath = lib.mkOption {
          description = "Path to the coturn config";
          type = lib.types.str;
        };
      };
      domains = {
        root = lib.mkOption {
          type = lib.types.str;
          default = "timeguard.ca";
        };
        matrix = lib.mkOption {
          type = lib.types.str;
          default = "matrix.${cfg.domains.root}";
        };
        livekit = lib.mkOption {
          type = lib.types.str;
          default = "livekit.${cfg.domains.root}";
        };
        webfinger = lib.mkOption {
          type = lib.types.str;
          default = "webfinger.${cfg.domains.root}";
        };
        redirect = lib.mkOption {
          type = lib.types.str;
          default = "blog.${cfg.domains.root}";
        };
      };
    };
    config = lib.mkIf cfg.enable {
      networking.firewall = {
        allowedTCPPorts = [
          # Livekit RTC TCP Port
          7881
          # TURN port
          3478
        ];
        allowedUDPPorts = [
          # TURN port
          3478
        ];
        # TCP and UDP ranges for both Livekit and Coturn
        allowedTCPPortRanges = [
          {
            from = 50100;
            to = 65535;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 50100;
            to = 65535;
          }
        ];
      };
      virtualisation.oci-containers.containers."lk-jwt-service" = {
        image = "ghcr.io/element-hq/lk-jwt-service:latest";
        environment = {
          "LIVEKIT_JWT_BIND" = ":8081";
          "LIVEKIT_URL" = "wss://${cfg.domains.livekit}";
        };
        environmentFiles = [
          cfg.config.livekitJWTEnvPath
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
          "caddy_0" = "${cfg.domains.livekit}";
          "caddy_0.@lk-jwt-service.path" = "/sfu/get* /healthz* /get_token*";
          "caddy_0.route" = "@lk-jwt-service";
          "caddy_0.route.reverse_proxy" = "{{upstreams 8081}}";
          "caddy_1" = "${cfg.domains.root}";
          "caddy_1.header" = "Access-Control-Allow-Origin *";
          "caddy_1.respond_0" = "/.well-known/matrix/server {\"m.server\":\"${cfg.domains.matrix}:443\"} 200";
          "caddy_1.respond_1" = "/.well-known/matrix/client {\"m.server\":{\"base_url\":\"https://${cfg.domains.matrix}\"},\"m.homeserver\":{\"base_url\":\"https://${cfg.domains.matrix}\"},\"m.identity_server\":{\"base_url\":\"https://${cfg.domains.matrix}\"},\"org.matrix.msc3575.proxy\":{\"url\":\"https://${cfg.domains.matrix}\"},\"org.matrix.msc4143.rtc_foci\":[{\"type\":\"livekit\",\"livekit_service_url\":\"https://${cfg.domains.livekit}\"}]} 200";
          "caddy_1.respond_2" = "/.well-known/matrix/support {\"contacts\":[{\"email_address\":\"${cfg.contactUser}@${cfg.domains.root}\",\"matrix_id\":\"@${cfg.contactUser}:${cfg.domains.root}\",\"role\":\"m.role.admin\"}]} 200";
          "caddy_1.redir_0" = "/.well-known/webfinger https://webfinger.timeguard.ca/.well-known/webfinger 301";
          "caddy_1.@well-known-matchers.not.path" = "/.well-known/matrix/* /.well-known/webfinger";
          "caddy_1.redir_1" = "@well-known-matchers https://${cfg.domains.redirect}{uri} 302";
        };
        log-driver = "journald";
        extraOptions = [
          "--network-alias=lk-jwt-service"
          "--network=matrix-backend-call-support_livekit_internal"
          "--network=${config.zelec-core.virtualisation.containers.caddy.dockerNetworkName}"
        ];
      };
      virtualisation.oci-containers.containers."livekit" = {
        image = "docker.io/livekit/livekit-server:latest";
        cmd = ["--config" "/etc/livekit.yaml"];
        ports = [
          "7881:7881/tcp"
          "50100-50200:50100-50200/tcp"
          "50100-50200:50100-50200/udp"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
          "caddy_0" = "${cfg.domains.livekit}";
          "caddy_0.reverse_proxy" = "{{upstreams 7880}}";
        };
        volumes = ["${cfg.config.livekitPath}:/etc/livekit.yaml:ro"];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=livekit"
          "--network=matrix-backend-call-support_livekit_internal"
          "--network=${config.zelec-core.virtualisation.containers.caddy.dockerNetworkName}"
        ];
      };
      virtualisation.oci-containers.containers."coturn" = {
        image = "docker.io/coturn/coturn:latest";
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        volumes = ["${cfg.config.coturnPath}:/etc/coturn/turnserver.conf:ro"];
        log-driver = "journald";
        extraOptions = ["--network=host"];
      };
      zelec-core.virtualisation.dockerManager.matrix-backend-call-support = {
        containerNames = [
          "coturn"
          "livekit"
          "lk-jwt-service"
        ];
        networkNames = [
          "livekit_internal"
        ];
      };
    };
  };
}
