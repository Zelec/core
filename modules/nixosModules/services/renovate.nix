# Setup an SSH key at /var/lib/renovate/.ssh/id_ed25519
# and a knownhosts file at /var/lib/renovate/.ssh/known_hosts
{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-renovate];
  };
  flake.nixosModules.services-renovate = {
    config,
    options,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.renovate;
  in {
    options.zelec-core.services.renovate = {
      enable = lib.mkEnableOption "Enables renovate service";
      platform = lib.mkOption {
        type = lib.types.str;
      };
      endpoint = lib.mkOption {
        type = lib.types.str;
      };
      tokenPath = lib.mkOption {
        type = lib.types.str;
      };
      githubTokenPath = lib.mkOption {
        type = lib.types.str;
      };
      sshKeyPath = lib.mkOption {
        type = lib.types.str;
      };
      runtimePackages = lib.mkOption {
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
          wget
        ];
      };
      extraKnownSSHKeys = lib.mkOption {
        description = options.programs.ssh.knownHosts.description;
        type = options.programs.ssh.knownHosts.type;
        default = {};
      };
      defaultKnownSSHKeys = lib.mkOption {
        description = options.programs.ssh.knownHosts.description;
        type = options.programs.ssh.knownHosts.type;
        default = {
          # Codeberg knownhost keys, pulled 2026-07-01
          # https://docs.codeberg.org/security/ssh-fingerprint/
          # https://codeberg.org/Codeberg/org/src/branch/main/Imprint.md#user-content-ssh-fingerprints
          "codeberg.org/ed25519" = {
            hostNames = ["codeberg.org"];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVIC02vnjFyL+I4RHfvIGNtOgJMe769VTF1VR4EB3ZB";
          };
          "codeberg.org/rsa" = {
            hostNames = ["codeberg.org"];
            publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8hZi7K1/2E2uBX8gwPRJAHvRAob+3Sn+y2hxiEhN0buv1igjYFTgFO2qQD8vLfU/HT/P/rqvEeTvaDfY1y/vcvQ8+YuUYyTwE2UaVU5aJv89y6PEZBYycaJCPdGIfZlLMmjilh/Sk8IWSEK6dQr+g686lu5cSWrFW60ixWpHpEVB26eRWin3lKYWSQGMwwKv4LwmW3ouqqs4Z4vsqRFqXJ/eCi3yhpT+nOjljXvZKiYTpYajqUC48IHAxTWugrKe1vXWOPxVXXMQEPsaIRc2hpK+v1LmfB7GnEGvF1UAKnEZbUuiD9PBEeD5a1MZQIzcoPWCrTxipEpuXQ5Tni4mN";
          };
          "codeberg.org/ecdsa-sha2-nistp256" = {
            hostNames = ["codeberg.org"];
            publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBL2pDxWr18SoiDJCGZ5LmxPygTlPu+cCKSkpqkvCyQzl5xmIMeKNdfdBpfbCGDPoZQghePzFZkKJNR/v9Win3Sc=";
          };
          # Github knownhost keys, pulled 2026-07-01
          # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
          "github.com/ed25519" = {
            hostNames = ["github.com"];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
          };
          "github.com/rsa" = {
            hostNames = ["github.com"];
            publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=";
          };
          "github.com/ecdsa-sha2-nistp256" = {
            hostNames = ["github.com"];
            publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=";
          };
          # Gitlab knownhost keys, pulled 2026-07-01
          # https://docs.gitlab.com/user/gitlab_com/#ssh-known_hosts-entries
          "gitlab.com/ed25519" = {
            hostNames = ["gitlab.com"];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
          };
          "gitlab.com/rsa" = {
            hostNames = ["gitlab.com"];
            publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9";
          };
          "gitlab.com/ecdsa-sha2-nistp256" = {
            hostNames = ["gitlab.com"];
            publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=";
          };
        };
      };
    };
    config = lib.mkIf cfg.enable {
      # Items to make frameworks like Sops Nix work better
      # And to make SSH access easier
      users.users.renovate = {
        isSystemUser = true;
        group = "renovate";
        home = "/var/lib/renovate";
      };
      users.groups.renovate = {};
      systemd.services.renovate = {
        serviceConfig = {
          User = "renovate";
          Group = "renovate";
          DynamicUser = lib.mkForce false; # fix
        };
      };
      systemd.tmpfiles.rules = [
        "d /var/lib/renovate/.ssh 0700 renovate renovate - -"
      ];
      home-manager.users.renovate = {
        home.stateVersion = "24.11";
        programs.ssh = {
          matchBlocks = {
            "*" = {
              hostname = "*";
              identityFile = "/var/lib/renovate/.ssh/id_ed25519";
            };
          };
        };
      };
      programs.ssh.knownHosts = cfg.defaultKnownSSHKeys // cfg.extraKnownSSHKeys;
      # Required to make the home manager block above work
      nix.settings.allowed-users = ["renovate"];
      services.renovate = {
        enable = true;
        runtimePackages = cfg.runtimePackages;
        validateSettings = true;
        # Every 10 mins
        schedule = "*:0/10";
        settings = {
          autodiscover = true;
          endpoint = cfg.endpoint;
          gitAuthor = "Renovate <renovate@timeguard.ca>";
          lockFileMaintenance.enabled = true;
          nix.enabled = true;
          onboardingConfig = {
            "$schema" = "https://docs.renovatebot.com/renovate-schema.json";
            extends = [
              "local>Renovate-Bot/renovate-config"
            ];
          };
          platform = cfg.platform;
          rebaseWhen = "behind-base-branch";
          timezone = config.zelec-core.base.timeZone;
        };
        environment = {
          # LOG_LEVEL = "debug";
          # Makes using git simpler
          GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -i \"${cfg.sshKeyPath}\" -o StrictHostKeyChecking=accept-new";
        };
        credentials = {
          RENOVATE_TOKEN = cfg.tokenPath;
          RENOVATE_GITHUB_COM_TOKEN = cfg.githubTokenPath;
        };
      };
    };
  };
}
