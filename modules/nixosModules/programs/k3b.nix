# KDE Disk Burner
# Normal k3b package fails to compile
# kdePackages.k3b actually installs
# Need to add /run/wrappers/bin into paths under
# Settings -> Configure K3b -> Search Path
# https://github.com/NixOS/nixpkgs/issues/19154#issuecomment-2468912624
{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-k3b];
  };
  flake.nixosModules.programs-k3b = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.k3b;
  in {
    options.zelec-core.programs.k3b = {
      enable = lib.mkEnableOption "Enables K3B";
    };
    config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        kdePackages.k3b
      ];
      services.udisks2.enable = true;
      security.wrappers = {
        cdrdao = {
          setuid = true;
          owner = "root";
          group = "cdrom";
          permissions = "u+wrx,g+x";
          source = "${pkgs.cdrdao}/bin/cdrdao";
        };
        cdrecord = {
          setuid = true;
          owner = "root";
          group = "cdrom";
          permissions = "u+wrx,g+x";
          source = "${pkgs.cdrtools}/bin/cdrecord";
        };
      };
    };
  };
}
