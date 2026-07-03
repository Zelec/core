{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-syncthing];
  };
  flake.nixosModules.services-syncthing = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.syncthing;
  in {
    options.zelec-core.services.syncthing = {
      enable = lib.mkEnableOption "Enables syncthing";
      user = lib.mkOption {
        type = lib.types.str;
        default = config.zelec-core.base.user.name;
      };
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/home/${cfg.user}/Sync";
      };
      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/home/${cfg.user}/.config/syncthing";
      };
      guiAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };
      guiPort = lib.mkOption {
        type = lib.types.port;
        default = 8384;
      };
      guiUser = lib.mkOption {
        type = lib.types.str;
        default = config.zelec-core.base.user.name;
      };
      guiPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
      };
      key = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to the Syncthing private key file.";
      };
      cert = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to the Syncthing certificate file.";
      };
    };
    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        services.syncthing = let
          portString = builtins.toString cfg.guiPort;
        in {
          enable = true;
          user = cfg.user;
          dataDir = cfg.dataDir;
          configDir = cfg.configDir;
          guiAddress = "${cfg.guiAddress}:${portString}";
          openDefaultPorts = true;
          # Apparently these override settings are set to true by default, not sure how I've never run into issues with this before
          # I guess this only turns into a problem if you've never set any declarative options prior and they
          # in turn build the syncthing-init service to set the settings.
          # Thank goodness I tested this before rolling it out to my important boxes
          overrideDevices = false;
          overrideFolders = false;
        };
        boot.kernel.sysctl = {
          "fs.inotify.max_user_watches" = lib.mkForce 1048576;
        };
      }
      (
        lib.mkIf (cfg.guiAddress == "0.0.0.0")
        {
          networking.firewall.allowedTCPPorts = [cfg.guiPort];
        }
      )
      (
        lib.mkIf (cfg.guiPasswordFile != null)
        {
          services.syncthing = {
            guiPasswordFile = cfg.guiPasswordFile;
            settings.gui.user = cfg.guiUser;
          };
        }
      )
      (
        lib.mkIf (cfg.key != null && cfg.cert != null)
        {
          services.syncthing = {
            key = cfg.key;
            cert = cfg.cert;
          };
        }
      )
    ]);
  };
}
