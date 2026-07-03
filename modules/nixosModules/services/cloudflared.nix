{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-cloudflared];
  };
  flake.nixosModules.services-cloudflared = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.cloudflared;

    processIngress = tunnelDefault: domain: value: let
      # Breakdown of setting up ingress rules
      # - If null? use tunnelDefault
      # - If it's an attrset? use value.service (fallback to tunnelDefault if service isn't defined)
      # - If it's a string? use value
      serviceAddr =
        if value == null
        then tunnelDefault
        else if lib.isAttrs value
        then (value.service or tunnelDefault)
        else value;

      base = {
        service = serviceAddr;
        originRequest = {
          originServerName = domain;
          httpHostHeader = domain;
        };
      };
    in
      if lib.isAttrs value
      then lib.recursiveUpdate base value
      else base;
  in {
    options.zelec-core.services.cloudflared = {
      enable = lib.mkEnableOption "Enables cloudflared";
      certificateFile = lib.mkOption {
        type = lib.types.str;
        description = "Path to argo tunnel token certificate file";
      };
      tunnels = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
          options = {
            credentialsFile = lib.mkOption {type = lib.types.path;};
            defaultEndpoint = lib.mkOption {
              type = lib.types.str;
              default = "https://localhost:443";
            };
            ingress = lib.mkOption {
              type = lib.types.attrsOf (lib.types.nullOr (lib.types.either lib.types.str lib.types.attrs));
              default = {};
            };
            default = lib.mkOption {
              type = lib.types.str;
              default = "http_status:404";
            };
          };
        }));
        default = {};
      };
    };
    config = lib.mkIf cfg.enable {
      # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
      boot.kernel.sysctl = {
        "net.core.rmem_max" = 7500000;
        "net.core.wmem_max" = 7500000;
      };
      services.cloudflared = {
        enable = true;
        certificateFile = cfg.certificateFile;
        tunnels =
          lib.mapAttrs (uuid: tunnelCfg: {
            inherit (tunnelCfg) credentialsFile default;
            ingress = lib.mapAttrs (processIngress tunnelCfg.defaultEndpoint) tunnelCfg.ingress;
          })
          cfg.tunnels;
      };
    };
  };
}
