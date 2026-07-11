{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.services-stylix];
  };
  flake.nixosModules.services-stylix = {
    config,
    options,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.services.stylix;
    default = options.stylix;
  in {
    imports = [
      inputs.stylix.nixosModules.stylix
    ];
    options.zelec-core.services.stylix = {
      enable = lib.mkEnableOption "Enables stylix";
      autoEnable = lib.mkOption {
        default = true;
        example = false;
        description = "Enables Stylix's autoEnable config";
        type = lib.types.bool;
      };
      image = lib.mkOption {
        type = default.image.type;
        default = ./wallpaper.jpg;
        example = "./wallpaper.jpg";
      };
      polarity = lib.mkOption {
        type = default.polarity.type;
        default = "dark";
      };
      base16Scheme = lib.mkOption {
        type = default.base16Scheme.type;
        default = {
          # Not much changed in here from Aidan's original Gigavolt theme
          # Just swapped the green (09) and the pink (0C) around so the green becomes the secondary accent in key parts
          # of the OS, and changed the blue to my favourite shade of blue, good ol #0AF lol
          name = "Gigavolt-mod";
          description = "Originally written by Aidan Swope (http://github.com/Whillikers)";
          author = "Isaac Towns (Zelec)";
          base00 = "#202126";
          base01 = "#2d303d";
          base02 = "#5a576e";
          base03 = "#a1d2e6";
          base04 = "#cad3ff";
          base05 = "#e9e7e1";
          base06 = "#eff0f9";
          base07 = "#f2fbff";
          base08 = "#ff661a";
          base09 = "#fb6acb";
          base0A = "#ffdc2d";
          base0B = "#f2e6a9";
          base0C = "#19f988";
          base0D = "#00aaff";
          base0E = "#ae94f9";
          base0F = "#6187ff";
        };
        example = "./base16-theme.yml";
      };
      fonts = lib.mkOption {
        type = lib.types.attrs;
        default = {
          serif = {
            package = pkgs.dejavu_fonts;
            name = "DejaVu Serif";
          };
          sansSerif = {
            package = pkgs.dejavu_fonts;
            name = "DejaVu Sans";
          };
          monospace = {
            package = pkgs.source-code-pro;
            name = "Source Code Pro";
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
      };
    };
    config = lib.mkIf cfg.enable {
      boot.plymouth.enable = true;
      stylix = {
        enable = true;
        # Breaks Plasma6 horribly
        # targets.qt.platform = lib.mkForce "qtct";
        autoEnable = cfg.autoEnable;
        image = cfg.image;
        polarity = cfg.polarity;
        base16Scheme = cfg.base16Scheme;
        fonts = cfg.fonts;
      };
      home-manager.users.${config.zelec-core.base.user.name} = {
        # Being managed by Plasma Manager, still references the above though
        stylix.targets.kde.useWallpaper = false;
      };
    };
  };
}
