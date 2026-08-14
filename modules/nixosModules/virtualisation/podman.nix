{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-podman];
  };
  flake.nixosModules.virtualisation-podman = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.podman;
    dockerEnabled = config.zelec-core.virtualisation.docker.enable or false;
    smartUpdateScript = pkgs.writeShellScript "smart-podman-update" ''
      set -euo pipefail

      OUTPUT=$(${pkgs.podman}/bin/podman auto-update --format json)
      UPDATED_COUNT=$(echo "$OUTPUT" | ${pkgs.jq}/bin/jq '[.[] | select(.Updated == "true")] | length')
      FAILED_COUNT=$(echo "$OUTPUT" | ${pkgs.jq}/bin/jq '[.[] | select(.Updated == "failed")] | length')
      if [ "$UPDATED_COUNT" -gt 0 ] && [ "$FAILED_COUNT" -eq 0 ]; then
        SUMMARY=$(echo "$OUTPUT" | ${pkgs.jq}/bin/jq -r '.[] | select(.Updated == "true") | "• \(.UnitName): Updated (Old: \(.ImageID[0:12]) -> New: \(.NewImageID[0:12]))"')
        ${pkgs.shoutrrr}/bin/shoutrrr send \
          --url "''${SHOUTARR_URL}" \
          --message "**Podman Auto-Update Success** ($UPDATED_COUNT updated):

      $SUMMARY"
      fi

      # Send targeted failure alert if specific containers failed
      if [ "$FAILED_COUNT" -gt 0 ]; then
        FAILED_SUMMARY=$(echo "$OUTPUT" | ${pkgs.jq}/bin/jq -r '.[] | select(.Updated == "failed") | "• \(.UnitName): Restart/Rollback Failed!"')

        ${pkgs.shoutrrr}/bin/shoutrrr send \
          --url "''${SHOUTARR_URL}" \
          --message "**Podman Container Update FAILED** ($FAILED_COUNT failed):

      $FAILED_SUMMARY"
      fi
    '';
    unitFailureScript = pkgs.writeShellScript "notify-podman-unit-failed" ''
      LOG_OUTPUT=$(${pkgs.systemd}/bin/journalctl -u podman-auto-update.service -n 25 --no-pager)

      ${pkgs.shoutrrr}/bin/shoutrrr send \
        --url "''${SHOUTARR_URL}" \
        --message "**podman-auto-update.service Crash**:

      \`\`\`
      $LOG_OUTPUT
      \`\`\`"
    '';
  in {
    imports = [
      inputs.quadlet-nix.nixosModules.quadlet
    ];
    options.zelec-core.virtualisation.podman = {
      enable = lib.mkEnableOption "Enables Podman and Quadlet support";
      autoUpdate = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automatic daily container updates via Podman auto-update";
        };
        schedule = lib.mkOption {
          type = lib.types.str;
          default = "02:00"; # Runs daily at 2:00 AM
          example = "Sun *-*-* 03:00:00"; # Weekly on Sunday at 3:00 AM
          description = "systemd OnCalendar expression defining when auto-updates trigger";
        };
        # WIP
        notificationENVFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "/run/secrets/podman-auto-update-shoutarr.env";
          description = ''
            Path to ENV file that contains the following:
            SHOUTARR_URL=discord://token@id
          '';
        };
      };
      storageDriver = lib.mkOption {
        type = lib.types.str;
        default = "btrfs";
        description = "Storage driver used by Podman backend";
      };
      nvidia.enable = lib.mkEnableOption "Enables NVIDIA support in Podman";
    };
    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.enable -> !dockerEnabled;
            message = ''
              Conflict detected in `zelec-core`:
              `zelec-core.virtualisation.docker.enable` cannot be `true` when using the Podman module.
              Please remove or set `zelec-core.virtualisation.docker.enable = false;`.
            '';
          }
        ];
      }
      (
        lib.mkIf cfg.enable
        {
          users.users.${config.zelec-core.base.user.name}.extraGroups = ["podman"];
          environment.sessionVariables = {
            # Yes I know, I really should not do this
            # I probably need some time yet to get fully off the docker way of working & thinking
            CONTAINER_HOST = "unix:///run/podman/podman.sock";
            # Gets rid of the compose redirection warning when ran
            PODMAN_COMPOSE_WARNING_LOGS = "false";
          };
          # If notifications are set
          systemd.services.podman-auto-update = lib.mkIf (cfg.autoUpdate.notificationENVFile != null) {
            unitConfig = {
              OnFailure = ["podman-auto-update-failure.service"];
            };
            serviceConfig = {
              EnvironmentFile = cfg.autoUpdate.notificationENVFile;
              ExecStart = ["" "${smartUpdateScript}"]; # Clear and override default command
            };
          };
          systemd.services."podman-auto-update-failure" = lib.mkIf (cfg.autoUpdate.notificationENVFile != null) {
            description = "Notify on total podman auto-update process failure";
            serviceConfig = {
              Type = "oneshot";
              EnvironmentFile = cfg.autoUpdate.notificationENVFile;
              ExecStart = "${unitFailureScript}";
            };
          };
          # Enables podman-restart on rootful & rootless user sockets
          # Useful for containers outside the scope of Quadlet-nix
          systemd.services.podman-restart.wantedBy = ["multi-user.target"];
          systemd.user.services.podman-restart.wantedBy = ["default.target"];
          virtualisation = {
            containers.enable = true;
            oci-containers.backend = "podman";
            podman = {
              enable = true;
              autoPrune = {
                enable = true;
                dates = "weekly";
                flags = ["--filter=label!=io.podman.prune.prevent=true"];
              };
              dockerCompat = true;
              dockerSocket.enable = true;
              defaultNetwork.settings.dns_enabled = true;
            };
            quadlet = {
              enable = true;
              autoUpdate.enable = cfg.autoUpdate.enable;
              autoUpdate.calendar = cfg.autoUpdate.schedule;
            };
            containers.storage.settings = {
              storage = {
                driver = cfg.storageDriver;
              };
            };
          };
          environment.systemPackages = with pkgs;
            [
              docker-compose
              podman
              podman-compose
            ]
            # NVIDIA / CDI Configuration
            ++ lib.optionals cfg.nvidia.enable [
              nvidia-container-toolkit
            ];
          hardware.nvidia-container-toolkit = lib.mkIf cfg.nvidia.enable {
            enable = true;
            mount-nvidia-executables = true;
            mount-nvidia-docker-1-directories = true;
            device-name-strategy = "index";
          };
          # Firewall configuration for Podman interfaces
          networking.firewall.trustedInterfaces = lib.mkIf config.networking.firewall.enable [
            "podman+"
            "br-+"
          ];
        }
      )
    ];
  };
}
