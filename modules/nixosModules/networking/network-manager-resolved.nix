{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.networking-nm-plus-resolved];
  };
  flake.nixosModules.networking-nm-plus-resolved = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.networking.nm-plus-resolved;
  in {
    options.zelec-core.networking.nm-plus-resolved = {
      enable = lib.mkEnableOption "Enables NetworkManager along with systemd-resolved";
    };
    config = lib.mkIf cfg.enable {
      networking = {
        networkmanager = {
          enable = true;
          dns = "systemd-resolved";
        };
      };
      services = {
        resolved = {
          enable = true;
          settings = {
            Resolve = {
              FallbackDNS = ["1.1.1.1" "1.0.0.1"];
            };
          };
        };
      };
    };
  };
}
