{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-beszel-agent];
  };
  flake.nixosModules.services-beszel-agent = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.beszel-agent;
  in {
    options.zelec-core.services.beszel-agent = {
      enable = lib.mkEnableOption "Enables beszel agent";
      envFilePath = lib.mkOption {
        type = lib.types.str;
        description = ''
          Path to a file with atleast the following
          ```
          KEY="ssh-ed25519 blablabla"
          TOKEN="00000000-0000-0000-0000-000000000000"
          HUB_URL="https://monitor.beszelserver.net"
          ```
          See the following for more details
          https://www.beszel.dev/guide/agent-installation
          https://www.beszel.dev/guide/environment-variables
        '';
      };
    };
    config = {
      services = {
        beszel.agent = {
          enable = true;
          package = pkgs.beszel;
          environmentFile = cfg.envFilePath;
          smartmon = {
            enable = true;
            package = pkgs.smartmontools;
          };
        };
      };
    };
  };
}
