{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-ddclient];
  };
  flake.nixosModules.services-ddclient = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.ddclient;
  in {
    options.zelec-core.services.ddclient = {
      enable = lib.mkEnableOption "Enables ddclient";
      passwordFile = lib.mkOption {
        type = lib.types.str;
      };
      configOptions = lib.mkOption {
        default = "";
        type = lib.types.lines;
      };
    };
    config = lib.mkIf cfg.enable {
      # Allows me to target Sops against a single group to make this play nicely
      users.groups.ddclient-secrets = {};
      systemd.services.ddclient = {
        serviceConfig = {
          SupplementaryGroups = lib.mkOptionDefault ["ddclient-secrets"];
          ReadOnlyPaths = lib.mkOptionDefault ["/run/secrets"];
        };
      };
      services.ddclient = {
        enable = true;
        usev4 = "webv4, web=ipinfo.io/ip";
        usev6 = "disabled";
        protocol = "cloudflare";
        ssl = true;
        username = "token";
        passwordFile = cfg.passwordFile;
        extraConfig = cfg.configOptions;
      };
    };
  };
}
