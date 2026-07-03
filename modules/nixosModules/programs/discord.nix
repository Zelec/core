{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-discord];
  };
  flake.nixosModules.programs-discord = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.discord;
  in {
    options.zelec-core.programs.discord = {
      enable = lib.mkEnableOption "Enables Discord";
    };
    config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        arrpc
      ];
      systemd.packages = with pkgs; [
        arrpc
      ];
      home-manager.users.${config.zelec-core.base.user.name} = {
        services.arrpc = {
          enable = true;
          package = pkgs.arrpc;
          systemdTarget = "graphical-session.target";
        };
        programs.vesktop = {
          enable = true;
          package = pkgs.unstable.vesktop.override {
            withTTS = true;
          };
          vencord.settings = {
            autoUpdate = true;
            autoUpdateNotification = true;
            notifyAboutUpdates = true;
            hardwareAcceleration = true;
            discordBranch = "stable";
            plugins = {
              ClearURLs.enabled = true;
              FixYoutubeEmbeds.enabled = true;
              YoutubeAdblock.enabled = true;
            };
          };
        };
      };
    };
  };
}
