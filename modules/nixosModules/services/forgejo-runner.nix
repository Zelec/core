{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-forgejo-runner];
  };
  flake.nixosModules.services-forgejo-runner = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.forgejo-runner;
  in {
    options.zelec-core.services.forgejo-runner = {
      enable = lib.mkEnableOption "Enables Forgejo Actions Runner Service";
      forgejoRunnerTokenPath = lib.mkOption {
        type = lib.types.str;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "${config.networking.hostName}";
      };
      url = lib.mkOption {
        type = lib.types.str;
        default = "https://git.tgdev.net";
      };
      cacheHost = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      runnerImageRoot = lib.mkOption {
        type = lib.types.str;
        default = "docker.tgdev.net/public/mirror/catthehacker/ubuntu";
      };
      enableGenericLabels = lib.mkOption {
        default = true;
        example = false;
        type = lib.types.bool;
      };
      enableGenericHostLabels = lib.mkOption {
        default = false;
        example = false;
        type = lib.types.bool;
      };
      enableSpesificHostLabels = lib.mkOption {
        default = true;
        example = false;
        type = lib.types.bool;
      };
      enablePrivilegedLabels = lib.mkOption {
        default = true;
        example = false;
        type = lib.types.bool;
      };
      containerOptions = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      enablePerSystemBuildLabels = lib.mkOption {
        default = false;
        example = true;
        type = lib.types.bool;
      };
      hostPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          bash
          coreutils
          curl
          gawk
          git
          gnused
          jq
          nix
          nodejs
          openssh
          ssh-agents
          wget
        ];
      };
    };
    config = lib.mkIf cfg.enable {
      services.gitea-actions-runner = {
        package = pkgs.forgejo-runner;
        instances = {
          base = {
            enable = true;
            name = "${cfg.name}-base";
            url = cfg.url;
            tokenFile = cfg.forgejoRunnerTokenPath;
            labels =
              lib.optionals cfg.enableGenericLabels [
                "ubuntu-latest:docker://${cfg.runnerImageRoot}:act-latest"
                "ubuntu-22.04:docker://${cfg.runnerImageRoot}:act-22.04"
                "ubuntu-20.04:docker://${cfg.runnerImageRoot}:act-20.04"
                "ubuntu-18.04:docker://${cfg.runnerImageRoot}:act-18.04"
                "nix-container:docker://docker.tgdev.net/public/nix-runner:latest"
              ]
              ++ lib.optionals cfg.enableSpesificHostLabels
              [
                "${cfg.name}-native:host"
                "${cfg.name}-nix-container:docker://docker.tgdev.net/public/nix-runner:latest"
                "${cfg.name}-ubuntu-latest:docker://${cfg.runnerImageRoot}:act-latest"
              ]
              ++ lib.optionals cfg.enableGenericHostLabels
              [
                "nix-native:host"
              ]
              ++ lib.optionals cfg.enablePerSystemBuildLabels
              [
                "nix-container-builder-${pkgs.stdenv.hostPlatform.system}:docker://docker.tgdev.net/public/nix-runner:latest"
              ];
            hostPackages = cfg.hostPackages;
            settings = {
              cache = {
                enabled = true;
                host = cfg.cacheHost;
              };
              container = {
                force_pull = true;
                privileged = false;
                options = cfg.containerOptions;
              };
              runner.capacity = 1;
            };
          };
          privileged-docker = {
            enable = cfg.enablePrivilegedLabels;
            name = "${cfg.name}-privileged-docker";
            url = cfg.url;
            tokenFile = cfg.forgejoRunnerTokenPath;
            labels = [
              "privileged-ubuntu-latest:docker://${cfg.runnerImageRoot}:act-latest"
              "privileged-ubuntu-22.04:docker://${cfg.runnerImageRoot}:act-22.04"
              "privileged-ubuntu-20.04:docker://${cfg.runnerImageRoot}:act-20.04"
              "privileged-ubuntu-18.04:docker://${cfg.runnerImageRoot}:act-18.04"
            ];
            hostPackages = cfg.hostPackages;
            settings = {
              cache = {
                enabled = true;
                host = cfg.cacheHost;
              };
              container = {
                force_pull = true;
                privileged = true;
                options = cfg.containerOptions;
              };
              runner.capacity = 1;
            };
          };
        };
      };
    };
  };
}
