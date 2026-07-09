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
    instanceOptions = {name, ...}: {
      options = {
        enable = lib.mkEnableOption "this zot docker proxy instance";
        domain = lib.mkOption {
          type = lib.types.str;
          description = "The domain name for the Caddy virtual host (e.g., 'docker.tgdev.net').";
        };
        internalAddress = lib.mkOption {
          type = lib.types.str;
          description = "The address for caddy to reach out to";
          default = "host.docker.internal";
        };
        proxyPort = lib.mkOption {
          type = lib.types.port;
          default = 5001;
          description = "The internal port the proxy should listen on.";
        };
        secretFile = lib.mkOption {
          type = lib.types.str;
          description = "Path to a file on the system containing the raw secret string.";
        };
        zotUrl = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:5000";
          description = "The upstream Zot URL.";
        };
      };
    };
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
      docker-proxy = {
        instances = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule instanceOptions);
          default = {};
          description = "Declarative instances of Zot Docker Proxies.";
        };
      };
    };
    config = lib.mkIf cfg.enable {
      zelec-core.virtualisation.containers.caddy.virtualHosts = lib.mapAttrs' (name: instanceCfg:
        lib.nameValuePair instanceCfg.domain {
          extraConfig = ''
            import base_config
            request_body {
              max_size 0
            }
            reverse_proxy ${toString instanceCfg.internalAddress}:${toString instanceCfg.proxyPort} {
              flush_interval -1
              header_up Host {http.request.host}
              transport http {
                dial_timeout 5s
              }
            }
          '';
        })
      cfg.docker-proxy.instances;
      services.zot-docker-proxy = {
        instances =
          lib.mapAttrs (name: instanceCfg: {
            configFile = "/run/zot-docker-proxy/${name}.conf";
          })
          cfg.docker-proxy.instances;
      };
      systemd.services = lib.mapAttrs' (name: instanceCfg:
        lib.nameValuePair "zot-docker-proxy-${name}" {
          serviceConfig = {
            # Ensure the directory exists and has strict permissions
            RuntimeDirectory = "zot-docker-proxy";
            RuntimeDirectoryMode = "0700";
          };

          # Before the service starts, substitute the secret into the template
          preStart = ''
            if [ ! -f "${instanceCfg.secretFile}" ]; then
              echo "Error: Secret file ${instanceCfg.secretFile} does not exist!" >&2
              exit 1
            fi

            SECRET=$(cat "${instanceCfg.secretFile}")

            # Write out the final config file safely to the runtime directory
            cat <<EOF > /run/zot-docker-proxy/${name}.conf
            port: ${toString instanceCfg.proxyPort}
            secret: ''${SECRET}
            zot-url: ${instanceCfg.zotUrl}
            my-url: https://${instanceCfg.domain}
            EOF

            chmod 600 /run/zot-docker-proxy/${name}.conf
          '';
        })
      cfg.docker-proxy.instances;
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
