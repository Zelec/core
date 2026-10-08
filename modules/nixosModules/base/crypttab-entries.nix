# Manager for /etc/crypttab entries
{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.base-crypttab-entries = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.base;
  in {
    options.zelec-core.base = {
      crypttab-entries = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            device = lib.mkOption {type = lib.types.str;};
            key = lib.mkOption {
              type = lib.types.str;
              default = "none";
            };
            options = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
          };
        });
        default = {};
        description = "Post-boot crypttab entries that will be automatically merged.";
      };
    };
    config = lib.mkIf (cfg.crypttab-entries != {}) {
      environment.etc.crypttab = {
        mode = "0600";
        text =
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: conf: "${name} ${conf.device} ${conf.key} ${conf.options}"
            )
            cfg.crypttab-entries
          )
          + "\n";
      };
    };
  };
}
