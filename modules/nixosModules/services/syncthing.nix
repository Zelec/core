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
    currentHost = config.networking.hostName;
  in {
    options.zelec-core.services.syncthing = {
      enable = lib.mkEnableOption "Enables syncthing";
      user = lib.mkOption {
        type = lib.types.str;
        default = config.zelec-core.base.user.name;
        description = "User to run the syncthing service under, defaults to `config.zelec-core.base.user.name`";
      };
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.zelec-core.base.user.homePath}/Sync";
        description = "Default share folder location, defaults to the Sync folder under `config.zelec-core.base.user.name`'s home folder";
      };
      configDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.zelec-core.base.user.homePath}/.config/syncthing";
        description = "Configuration directory for syncthing, defaults to the .config/syncthing under `config.zelec-core.base.user.name`'s home folder";
      };
      guiAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host binding for syncthing's GUI address (Only use this to set the binding, if you want to bind to all addresses set `cfg.guiBindToAllInterfaces` to true instead) otherwise syncthing-init.service will break";
      };
      guiPort = lib.mkOption {
        type = lib.types.port;
        default = 8384;
        description = "Port used for Syncthing's GUI";
      };
      guiBindToAllInterfaces = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Workaround for syncthing-init.service's curl commands, instead adds an additional bind parameter to syncthing's normal extraFlags";
      };
      guiUser = lib.mkOption {
        type = lib.types.str;
        default = config.zelec-core.base.user.name;
        description = "Username to use for the syncthing's webui";
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
      devices = lib.mkOption {
        type = lib.types.nullOr lib.types.attrs;
        default = null;
      };
      folders = lib.mkOption {
        type = lib.types.nullOr lib.types.attrs;
        default = null;
      };
    };
    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        warnings = lib.optional (cfg.guiAddress == "0.0.0.0") ''
          Warning from `zelec-core.services.syncthing`:
          `zelec-core.services.syncthing.guiAddress` is set to bind to "0.0.0.0".
          if you want to bind to all addresses set `zelec-core.services.syncthing.guiBindToAllInterfaces = true;` instead.
          This setup otherwise will break how the syncthing-init.service works since curl won't understand how to talk to "0.0.0.0"
        '';
        services.syncthing = let
          portString = toString cfg.guiPort;
        in {
          enable = true;
          inherit (cfg) user dataDir configDir;
          guiAddress = "${cfg.guiAddress}:${portString}";
          openDefaultPorts = true;
          # Apparently these override settings are set to true by default, not sure how I've never run into issues with this before
          # I guess this only turns into a problem if you've never set any declarative options prior and they
          # in turn build the syncthing-init service to set the settings.
          # Thank goodness I tested this before rolling it out to my important boxes
          overrideDevices = lib.mkDefault false;
          overrideFolders = lib.mkDefault false;
          settings.options.urAccepted = lib.mkDefault (-1);
        };
        boot.kernel.sysctl = {
          "fs.inotify.max_user_watches" = lib.mkForce 1048576;
        };
      }
      (lib.mkIf (cfg.guiBindToAllInterfaces == true) {
        networking.firewall.allowedTCPPorts = [cfg.guiPort];
        # To fix syncthing-init's binding issues, don't touch guiAddress anymore, use guiBindToAllInterfaces instead
        services.syncthing.extraFlags = ["--gui-address=0.0.0.0:${toString cfg.guiPort}"];
      })
      (lib.mkIf (cfg.guiPasswordFile != null) {
        services.syncthing = {
          inherit (cfg) guiPasswordFile;
          settings.gui.user = cfg.guiUser;
        };
      })
      (lib.mkIf (cfg.key != null && cfg.cert != null) {
        services.syncthing = {
          inherit (cfg) key cert;
        };
      })
      (lib.mkIf (cfg.devices != null) {
        services.syncthing.settings.devices = lib.pipe cfg.devices [
          # Automatically strip current host out of the devices list
          # deadnix: skip
          (lib.filterAttrs (name: _: name != currentHost))
          # deadnix: skip
          (lib.mapAttrs (name: deviceCfg: {addresses = lib.mkDefault ["dynamic"];} // deviceCfg))
        ];
      })
      (lib.mkIf (cfg.devices != null) {
        services.syncthing.settings.folders = lib.pipe cfg.folders [
          # Only define locally if the current host is in the folder's device peer list
          # deadnix: skip
          (lib.filterAttrs (name: folder: builtins.elem currentHost folder.devices))
          # deadnix: skip
          (lib.mapAttrs (name: folderCfg:
            {path = lib.mkDefault "${config.zelec-core.base.user.homePath}/${folderCfg.label or name}";}
            // folderCfg
            // {
              # Automatically strip current host out of the folder's peer devices list
              devices = builtins.filter (d: d != currentHost) folderCfg.devices;
            }))
        ];
      })
    ]);
  };
}
