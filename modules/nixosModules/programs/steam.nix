{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-steam];
  };
  flake.nixosModules.programs-steam = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.steam;
  in {
    options.zelec-core.programs.steam = {
      enable = lib.mkEnableOption "Enables steam";
    };
    config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        pkgs.unstable.r2modman
        lutris
      ];
      programs = {
        gamemode.enable = true;
        gamescope = {
          enable = true;
          capSysNice = true;
        };
        steam = {
          enable = true;
          remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
          dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
          localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
        };
      };
      boot.kernel.sysctl = {
        "kernel.sched_cfs_bandwidth_slice_us" = 3000;
        "net.ipv4.tcp_fin_timeout" = 5;
        "vm.max_map_count" = 2147483642;
      };
      # To make gamemode cpu/gpu governors work
      security.polkit.enable = true;
    };
  };
}
