{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-flatpak];
  };
  flake.nixosModules.services-flatpak = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.flatpak;
  in {
    imports = [
      inputs.nix-flatpak.nixosModules.nix-flatpak
    ];
    options.zelec-core.services.flatpak = {
      enable = lib.mkEnableOption "Enables flatpak autoconfig";
    };
    config = lib.mkIf cfg.enable {
      services = {
        flatpak = {
          enable = true;
          remotes = [
            {
              name = "flathub";
              location = "https://flathub.org/repo/flathub.flatpakrepo";
            }
          ];
          # TODO: I should get rid of this and make my installs use good ol' nixpkgs instead
          # Don't get me wrong flatpak is great for oneoffs, or certain programs who only want to be
          # distributed via flatpaks (Such as bottles)
          # But I really should embrace nixpkgs for most of my software needs.
          packages = [
            "com.usebottles.bottles"
            "org.signal.Signal"
          ];
          update.auto = {
            enable = true;
            onCalendar = "weekly";
          };
          uninstallUnused = true;
        };
        fwupd.enable = true;
        packagekit.enable = true;
      };
      # To allow testing if no desktop environment is being used
      xdg.portal = lib.mkDefault {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common.default = ["gtk"];
        xdgOpenUsePortal = true;
      };
    };
  };
}
