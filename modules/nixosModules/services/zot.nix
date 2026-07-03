{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-zot];
  };
  flake.nixosModules.services-zot = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.zot;
  in {
    options.zelec-core.services.zot = {
      enable = lib.mkEnableOption "Enables Zot OCI container registry";
      htpasswdPath = lib.mkOption {
        type = lib.types.str;
      };
      httpAccessControl = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        example = {
          adminPolicy = {
            users = ["admin"];
            actions = ["read" "create" "update" "delete"];
          };
          repositories = {
            "**" = {
              policies = [
                {
                  users = ["ci-readonly"];
                  actions = ["read"];
                }
              ];
            };
            "public/**" = {
              policies = [
                {
                  users = ["alice" "ci-public-mirror"];
                  actions = ["read" "create" "update" "delete"];
                }
              ];
              anonymousPolicy = ["read"];
              defaultPolicy = ["read"];
            };
            "repo-1/**" = {
              policies = [
                {
                  users = ["bob" "ci-repo-1"];
                  actions = ["read" "create" "update" "delete"];
                }
              ];
            };
            "repo-2/**" = {
              policies = [
                {
                  users = ["alice" "ci-repo-2"];
                  actions = ["read" "create" "update" "delete"];
                }
              ];
            };
          };
        };
      };
      caddy = {
        domain = lib.mkOption {
          type = lib.types.str;
          default = "docker.tgdev.net";
        };
        domainAliases = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = ["docker.tgdev.ca"];
        };
        internalAddress = lib.mkOption {
          type = lib.types.str;
          default = "host.docker.internal";
        };
        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = ''
            import base_config
            request_body {
              max_size 0
            }
            reverse_proxy ${cfg.caddy.internalAddress}:${config.services.zot.settings.http.port} {
              flush_interval -1
              header_up Host {http.request.host}
              transport http {
                dial_timeout 5s
              }
            }
          '';
        };
      };
    };
    config = lib.mkIf cfg.enable {
      zelec-core.virtualisation.containers.caddy.virtualHosts."${cfg.caddy.domain}" = {
        serverAliases = cfg.caddy.domainAliases;
        extraConfig = cfg.caddy.extraConfig;
      };
      services.zot = {
        enable = true;
        dataDir = "/var/lib/zot";
        user = "zot";
        group = "zot";
        settings = {
          extensions.lint.enable = false;
          storage.dedupe = true;
          http = {
            port = "5000";
            compat = ["docker2s2"];
            auth = {
              htpasswd.path = cfg.htpasswdPath;
              failDelay = 1;
            };
            accessControl = cfg.httpAccessControl;
          };
        };
        retention = {
          dryRun = false;
          delay = "24h";
          policies = [];
          defaultPolicy = {
            deleteReferrers = false;
            deleteUntagged = true;
            keepTags = [
              {patterns = [".*"];}
            ];
          };
        };
      };
    };
  };
}
