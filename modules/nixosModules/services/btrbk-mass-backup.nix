{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-btrbk-mass-backup];
  };
  flake.nixosModules.services-btrbk-mass-backup = {
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
