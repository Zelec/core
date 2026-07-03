# Heavy inspiration from compose2nix
# https://github.com/aksiksi/compose2nix
# But I much prefer this mainly nix setup vs converting each compose file into a nix file
# Limitiations to be aware of, all containers defined in a project will wait for the volumes and networks to be created
# Doesn't matter for my simple single stacks, but for more complex setups it could make you wait longer than you'd like
{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-dockerManager];
  };
  flake.nixosModules.virtualisation-dockerManager = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.dockerManager;
    # Works in tandem with the enable option to only activate submodule declarations who have enable set to true
    # Every submodule will be enabled by default, because yeah ofcourse you declare a submodule you'd assume it's needed
    # but it could come in handy for some people, or myself in the future to disable stacks when brought in.
    enabledInstances = lib.filterAttrs (_: instance: instance.enable) cfg;
  in {
    options.zelec-core.virtualisation.dockerManager = lib.mkOption {
      description = "Docker manager instances";
      default = {};
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          enable = lib.mkOption {
            default = true;
            example = false;
            description = "Enables submodule instance for the docker manager";
            type = lib.types.bool;
          };
          projectName = lib.mkOption {
            type = lib.types.str;
            default = name;
          };
          containerNames = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          networkNames = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          volumeNames = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
        };
      }));
    };

    config = {
      systemd.targets = lib.mkMerge (lib.mapAttrsToList (name: instanceCfg: {
          "docker-compose-${instanceCfg.projectName}-root" = {
            unitConfig.Description = "Root target generated in nix code for ${name}, inspired by compose2nix";
            wantedBy = ["multi-user.target"];
          };
        })
        enabledInstances);

      systemd.services = lib.mkMerge (lib.mapAttrsToList (
          name: instanceCfg: let
            # Dynamically build the list of service dependencies
            networkServices = map (net: "docker-network-${instanceCfg.projectName}_${net}.service") instanceCfg.networkNames;
            volumeServices = map (vol: "docker-volume-${instanceCfg.projectName}_${vol}.service") instanceCfg.volumeNames;
            allDependencies = networkServices ++ volumeServices;
          in
            lib.mkMerge [
              # Network services
              (lib.listToAttrs (map (networkName: {
                  name = "docker-network-${instanceCfg.projectName}_${networkName}";
                  value = {
                    path = [pkgs.docker];
                    serviceConfig = {
                      Type = "oneshot";
                      RemainAfterExit = true;
                      ExecStop = "${pkgs.docker}/bin/docker network rm -f ${instanceCfg.projectName}_${networkName}";
                    };
                    script = "docker network inspect ${instanceCfg.projectName}_${networkName} || docker network create ${instanceCfg.projectName}_${networkName}";
                    partOf = ["docker-compose-${instanceCfg.projectName}-root.target"];
                    wantedBy = ["docker-compose-${instanceCfg.projectName}-root.target"];
                  };
                })
                instanceCfg.networkNames))

              # Volume services
              (lib.listToAttrs (map (volumeName: {
                  name = "docker-volume-${instanceCfg.projectName}_${volumeName}";
                  value = {
                    path = [pkgs.docker];
                    serviceConfig = {
                      Type = "oneshot";
                      RemainAfterExit = true;
                    };
                    script = "docker volume inspect ${instanceCfg.projectName}_${volumeName} || docker volume create ${instanceCfg.projectName}_${volumeName}";
                    partOf = ["docker-compose-${instanceCfg.projectName}-root.target"];
                    wantedBy = ["docker-compose-${instanceCfg.projectName}-root.target"];
                  };
                })
                instanceCfg.volumeNames))

              # Container service overrides
              (lib.listToAttrs (map (containerName: {
                  name = "docker-${containerName}";
                  value = {
                    serviceConfig = {
                      Restart = lib.mkOverride 90 "always";
                      RestartMaxDelaySec = lib.mkOverride 90 "1m";
                      RestartSec = lib.mkOverride 90 "5s";
                      RestartSteps = lib.mkOverride 90 9;
                    };
                    # Dynamically injected dependencies
                    after = allDependencies;
                    requires = allDependencies;
                    partOf = ["docker-compose-${instanceCfg.projectName}-root.target"];
                    wantedBy = ["docker-compose-${instanceCfg.projectName}-root.target"];
                  };
                })
                instanceCfg.containerNames))
            ]
        )
        enabledInstances);
    };
  };
}
