{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-adb];
  };
  flake.nixosModules.programs-adb = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.adb;
  in {
    options.zelec-core.programs.adb = {
      enable = lib.mkEnableOption "Enables ADB";
    };
    config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        android-tools
      ];
      users.users.${config.zelec-core.base.user.name}.extraGroups = ["adbusers"];
    };
  };
}
