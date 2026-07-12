# Default modules for all systems
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.base];
  };
  flake.nixosModules.base = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.base;
  in {
    imports = with self.nixosModules; [
      # Other base modules
      base-nix-common
      base-system-tweaks
      base-user
      # Default module imports that don't have a better spot to live
      inputs.copyparty.nixosModules.default
      inputs.nix-index-database.nixosModules.default
    ];
    options.zelec-core = {
      autoEnable = lib.mkOption {
        description = "This option enables some modules to enable themselves, leave this off to make all modules opt-in";
        type = lib.types.bool;
        default = false;
      };
      base = {
        enable = lib.mkOption {
          description = "Turns on base-module options";
          type = lib.types.bool;
          default = cfgRoot.autoEnable;
        };
        timeZone = lib.mkOption {
          type = lib.types.str;
          default = "America/Toronto";
        };
      };
    };
    config = lib.mkIf cfg.enable {
      # Default internal modules used by all machines
      zelec-core = {
        base = {
          nix-common.enable = lib.mkDefault cfgRoot.autoEnable;
          system-tweaks.enable = lib.mkDefault cfgRoot.autoEnable;
          user.enable = lib.mkDefault cfgRoot.autoEnable;
        };
        programs.common-cli.enable = lib.mkDefault cfgRoot.autoEnable;
        services.beszel-agent = {
          enable = lib.mkDefault cfgRoot.autoEnable;
          enableSmart = lib.mkDefault cfgRoot.autoEnable;
        };
        services.locate.enable = lib.mkDefault cfgRoot.autoEnable;
        services.openssh.enable = lib.mkDefault cfgRoot.autoEnable;
        services.stylix.enable = lib.mkDefault cfgRoot.autoEnable;
      };
      programs.nix-index-database.comma.enable = lib.mkDefault cfgRoot.autoEnable;
      services.fstrim.enable = lib.mkDefault cfgRoot.autoEnable;
    };
  };
}
