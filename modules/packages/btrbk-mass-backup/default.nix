{self, ...}: {
  perSystem = {pkgs, ...}: let
  in {
    packages = {
      btrbk-mass-backup = pkgs.writeShellApplication {
        name = "btrbk-mass-backup";
        runtimeInputs = [
          pkgs.jq
          pkgs.btrfs-progs
          pkgs.coreutils
          pkgs.findutils
          pkgs.util-linux
        ];
        text = ''
          ACTION="" CONFIG_FILE="" MOUNT_POINT="" MAPPER_DEVICE=""

          usage() {
            echo "Usage: $0 --prepare|--cleanup --config [json] --mount-point [path] --mapper [path]"
            exit 1
          }

          while [[ $# -gt 0 ]]; do
            case "$1" in
              --prepare) ACTION="prepare" ;;
              --cleanup) ACTION="cleanup" ;;
              --config) CONFIG_FILE="$2"; shift ;;
              --mount-point) MOUNT_POINT="$2"; shift ;;
              --mapper) MAPPER_DEVICE="$2"; shift ;;
              *) usage ;;
            esac
            shift
          done

          if [[ -z "$ACTION" || -z "$CONFIG_FILE" || -z "$MOUNT_POINT" || -z "$MAPPER_DEVICE" ]]; then usage; fi

          if [[ "$(id -u)" -ne 0 ]]; then
            echo "Error: Not running as root" >&2
            exit 1
          fi

          if [[ "$ACTION" == "prepare" ]]; then
            if [[ ! -e "$MAPPER_DEVICE" ]]; then
              echo "Error: $MAPPER_DEVICE not found. Is the drive plugged in?" >&2
              exit 1
            fi
            if ! mountpoint -q "$MOUNT_POINT"; then
              echo "Error: Mount point $MOUNT_POINT not active." >&2
              exit 1
            fi
            echo "Mount check passed. Proceeding with snapshots..."
          fi

          # Parse JSON and loop over entries
          while IFS=$'\t' read -r archive host loc subvol; do
            host_archive="''${archive}/''${host}"
            target_path="''${host_archive}/''${subvol}"

            if [[ "''${ACTION}" == "prepare" ]]; then
              # Ensure archive folders exist as subvolumes
              if [[ ! -e "''${archive}" ]]; then btrfs subvolume create "''${archive}"; fi
              if [[ ! -e "''${host_archive}" ]]; then btrfs subvolume create "''${host_archive}"; fi

              # Find the latest subvolume matching the btrbk pattern (name.YYYYMMDDTHHMM)
              # Replicates Python logic: item[:-14] == subvol
              latest=$(find "''${loc}" -maxdepth 1 -mindepth 1 -printf "%f\n" | while read -r item; do
                if [[ "''${#item}" -gt 14 ]]; then
                  prefix="''${item:0:''${#item}-14}"
                  if [[ "''${prefix}" == "''${subvol}" ]]; then
                    echo "''${item}"
                  fi
                fi
              done | sort | tail -n 1)

              if [[ -n "''${latest}" ]]; then
                echo "Snapshotting: ''${loc}/''${latest} -> ''${target_path}"
                if [[ -e "''${target_path}" ]]; then
                  btrfs subvolume delete "''${target_path}"
                fi
                btrfs subvolume snapshot -r "''${loc}/''${latest}" "''${target_path}"
              else
                echo "Warning: No snapshots found for ''${subvol} in ''${loc}"
              fi

            elif [[ "''${ACTION}" == "cleanup" ]]; then
              if [[ -e "''${target_path}" ]]; then
                echo "Cleaning up: ''${target_path}"
                btrfs subvolume delete "''${target_path}"
              fi
            fi
          done < <(jq -r '
            to_entries[] | .key as $archive |
            .value | to_entries[] | .key as $host |
            .value | to_entries[] | .key as $loc |
            .value[] |
            "\($archive)\t\($host)\t\($loc)\t\(.)"
          ' "''${CONFIG_FILE}")

          if [[ "$ACTION" == "cleanup" ]]; then
            if mountpoint -q "$MOUNT_POINT"; then
              echo "Syncing and unmounting $MOUNT_POINT..."
              sync "$MOUNT_POINT"
              umount "$MOUNT_POINT"
              echo "Cleanup complete."
            fi
          fi
        '';
      };
    };
    devShells.btrbk-mass-backup = pkgs.mkShell {
      packages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.btrbk-mass-backup
      ];
    };
  };

  flake.nixosModules.btrbk-mass-backup = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.zelec-core.services.btrbk-mass-backup;
    mapperFullName = "/dev/mapper/${cfg.mapperName}";
    configJson = pkgs.writeText "btrbk-mass-backup-config.json" (builtins.toJSON cfg.volumes);
    backupBin = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.btrbk-mass-backup} --config ${configJson} --mount-point ${cfg.mountPoint} --mapper ${mapperFullName}";
  in {
    options.zelec-core.services.btrbk-mass-backup = {
      enable = lib.mkOption {
        type = lib.types.bool;
        example = false;
        default = true;
      };
      mountPoint = lib.mkOption {
        type = lib.types.str;
        default = "/media/secureArchiveStorage";
      };
      mapperName = lib.mkOption {
        type = lib.types.str;
        default = "rotatedDrives";
      };
      deviceLabel = lib.mkOption {
        type = lib.types.str;
        default = "TG-Backup-Drive-Crypt";
      };
      deviceEncryptionKeyPath = lib.mkOption {
        type = lib.types.str;
        default = "./luks-key";
      };
      volumes = lib.mkOption {
        description = "JSON-compatible attrset defining backup hierarchy (See example.json for format)";
        type = lib.types.attrsOf (lib.types.attrsOf (lib.types.attrsOf (lib.types.listOf lib.types.str)));
        default = {};
      };
      resticRepoKeyPath = lib.mkOption {
        type = lib.types.str;
        default = "./secret.txt";
      };
      resticExcludes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          ".cache/"
          ".config/Code/Cache/"
          ".config/Code/CachedData/"
          ".config/VSCodium/Cache/"
          ".config/VSCodium/CachedData/"
          ".local/share/baloo/"
          ".local/share/Steam/"
          ".var/app/*/cache/"
          ".var/app/*/config/*/sessionData/Cache/"
          "nix/store/"
        ];
      };
      calendarTime = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 21:13:00";
      };
    };
    config = lib.mkIf cfg.enable {
      services.restic.backups.archive = {
        backupPrepareCommand = "${backupBin} --prepare";
        backupCleanupCommand = "${backupBin} --cleanup";
        passwordFile = cfg.resticRepoKeyPath;
        pruneOpts = [
          "--keep-daily 14"
          "--keep-weekly 8"
          "--keep-monthly 12"
          "--keep-yearly 75"
        ];
        progressFps = 0.2;
        exclude = cfg.resticExcludes;
        paths = lib.attrNames cfg.volumes;
        repository = "${cfg.mountPoint}/restic-archive";
        initialize = true;
        timerConfig = {
          OnCalendar = cfg.calendarTime;
        };
      };

      systemd.services.restic-backups-archive = {
        unitConfig.RequiresMountsFor = "${cfg.mountPoint}";
      };

      environment.etc.crypttab = {
        mode = "0600";
        text = ''
          ${cfg.mapperName} /dev/disk/by-label/${cfg.deviceLabel} ${cfg.deviceEncryptionKeyPath} luks,noauto,nofail,discard
        '';
      };

      systemd.services."systemd-cryptsetup@${cfg.mapperName}" = {
        overrideStrategy = "asDropin";
        unitConfig = {
          StopWhenUnneeded = true;
          StopPropagatedFrom = ["${lib.replaceStrings ["/"] ["-"] (lib.removePrefix "/" cfg.mountPoint)}.mount"];
        };
      };

      systemd.mounts = [
        {
          where = cfg.mountPoint;
          what = mapperFullName;
          type = "ext4";
          mountConfig = {
            TimeoutSec = "15s";
            Options = "noatime,noauto,nofail";
          };
          unitConfig = {
            BindsTo = ["systemd-cryptsetup@${cfg.mapperName}.service"];
            After = ["systemd-cryptsetup@${cfg.mapperName}.service"];
            Requires = ["systemd-cryptsetup@${cfg.mapperName}.service"];
          };
        }
      ];

      systemd.automounts = [
        {
          description = "Automount for Rotated Encrypted Data Drives";
          where = cfg.mountPoint;
          wantedBy = ["multi-user.target"];
          automountConfig.TimeoutIdleSec = "300s";
        }
      ];

      systemd.tmpfiles.rules = [
        "d ${cfg.mountPoint} 0750 root root - -"
        "h ${cfg.mountPoint} - - - - +i"
      ];
    };
  };
}
