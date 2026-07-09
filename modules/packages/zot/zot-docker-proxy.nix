{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: let
  in {
    packages = {
      zot-docker-proxy = pkgs.buildGoModule {
        pname = "zot-docker-proxy";
        version = "1.0.0";
        src = pkgs.fetchFromGitHub {
          owner = "USA-RedDragon";
          repo = "zot-docker-proxy";
          rev = "25564291d3319bb1edf16ee54e17dda28bb1799c";
          sha256 = "sha256-bM5RP3dNnQAX/nDnNQ4qb0THwlTb+S4GW1iTXhWhcC8=";
        };
        vendorHash = "sha256-6rKU4oFAT3kZ006YcTx9fMPTPGfqGCqVXJJL+27Ti4k=";
        doCheck = true;
        meta = {
          description = "A simple proxy server for Zot to enable use of the Docker CLI.";
          homepage = "https://github.com/USA-RedDragon/zot-docker-proxy";
          license = pkgs.lib.licenses.mit;
          mainProgram = "zot-docker-proxy";
        };
      };
    };
  };
  flake.nixosModules.services-zot = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.zot-docker-proxy;
    package = self.packages.${pkgs.stdenv.hostPlatform.system}.zot-docker-proxy;
    enabledInstances = lib.filterAttrs (_: instance: instance.enable) cfg.instances;
  in {
    options.services.zot-docker-proxy = {
      user = lib.mkOption {
        type = lib.types.str;
        default = "zot-docker-proxy";
        description = "User to run the service as.";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "zot-docker-proxy";
        description = "Group to run the service as.";
      };
      instances = lib.mkOption {
        description = "Docker manager instances";
        default = {};
        type = lib.types.attrsOf (lib.types.submodule ({
            name,
            config ? {},
            ...
          } @ submoduleArgs: let
            subConfig = submoduleArgs.config or submoduleArgs;
          in {
            options = {
              enable = lib.mkOption {
                default = true;
                example = false;
                description = "Enables zot-docker-proxy service";
                type = lib.types.bool;
              };
              instanceName = lib.mkOption {
                type = lib.types.str;
                default = name;
              };
              logLevel = lib.mkOption {
                type = lib.types.nullOr (lib.types.enum ["debug" "info" "warn" "error"]);
                default = null;
              };
              port = lib.mkOption {
                type = lib.types.nullOr lib.types.ints.unsigned;
                default = null;
              };
              secret = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              secretFile = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              zotUrl = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              myUrl = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              corsAllowedOrigins = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              configFile = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };

              _hasStructuredConfig = lib.mkOption {
                type = lib.types.bool;
                internal = true;
                default =
                  subConfig.port
                  != null
                  || subConfig.logLevel != null
                  || subConfig.secret != null
                  || subConfig.secretFile != null
                  || subConfig.zotUrl != null
                  || subConfig.myUrl != null
                  || subConfig.corsAllowedOrigins != null;
              };
            };
          }));
      };
    };
    config = lib.mkIf (enabledInstances != {}) {
      assertions = lib.concatLists (lib.mapAttrsToList (name: instanceCfg: [
          {
            assertion = !(instanceCfg.configFile != null && instanceCfg._hasStructuredConfig);
            message = ''
              [zot-docker-proxy instance: ${name}] Cannot set both 'configFile' and individual environment configuration options.
            '';
          }
          {
            assertion = !(instanceCfg.secret != null && instanceCfg.secretFile != null);
            message = ''
              [zot-docker-proxy instance: ${name}] Cannot set both a secret and secretFile.
            '';
          }
        ])
        enabledInstances);
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
      };
      users.groups.${cfg.group} = {};
      systemd.services =
        lib.mapAttrs' (
          name: instanceCfg:
            lib.nameValuePair "zot-docker-proxy-${name}" {
              description = "Zot-Docker-Proxy instance: ${name}";
              wantedBy = ["multi-user.target"];
              after = ["network.target"];
              environment = lib.mkIf (instanceCfg.configFile == null) (lib.filterAttrs (n: v: v != null) {
                LOG_LEVEL = instanceCfg.logLevel;
                PORT =
                  if instanceCfg.port != null
                  then toString instanceCfg.port
                  else null;
                SECRET = instanceCfg.secret;
                ZOT_URL = instanceCfg.zotUrl;
                MY_URL = instanceCfg.myUrl;
                CORS_ALLOWED_ORIGINS = instanceCfg.corsAllowedOrigins;
              });
              serviceConfig = {
                Type = "simple";
                ExecStart =
                  if instanceCfg.configFile != null
                  then "${lib.getExe package} --config ${instanceCfg.configFile}"
                  else "${lib.getExe package}";
                Restart = "on-failure";
                User = cfg.user;
                Group = cfg.group;
                LimitNOFILE = 500000;
                PrivateTmp = true;
                ProtectHome = true;
                NoNewPrivileges = true;
              };
            }
        )
        enabledInstances;
    };
  };
}
