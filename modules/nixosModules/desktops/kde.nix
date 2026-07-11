{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.desktops-kde];
  };
  flake.nixosModules.desktops-kde = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.desktops.kde;
  in {
    options.zelec-core.desktops.kde = {
      enable = lib.mkEnableOption "Turns on KDE Desktop";
    };
    config = lib.mkIf cfg.enable {
      zelec-core = {
        hardware.bluetooth.enable = lib.mkDefault true;
        services.pipewire.enable = lib.mkDefault true;
        services.printing.enable = lib.mkDefault true;
      };
      environment.systemPackages = with pkgs.kdePackages;
        [
          ark
          dolphin
          filelight
          gwenview
          isoimagewriter
          k3b
          kcalc
          kcharselect
          kclock
          kcolorchooser
          kdenlive
          kfind
          kolourpaint
          kpat
          ksystemlog
          partitionmanager
          sddm-kcm
          spectacle
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
          discover
        ];
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      fonts.packages = with pkgs; [
        dejavu_fonts
        font-awesome
        nerd-fonts.jetbrains-mono
        noto-fonts-color-emoji
        source-code-pro
      ];
      hardware.graphics = {
        enable = true;
        enable32Bit = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 true;
      };
      services = {
        displayManager = {
          defaultSession = "plasma";
          sddm = {
            enable = true;
            wayland.enable = true;
          };
          autoLogin = {
            enable = true;
            user = config.zelec-core.base.user.name;
          };
        };
        desktopManager.plasma6.enable = true;
        fstrim.enable = true;
        fwupd.enable = true;
        gvfs.enable = true;
        libinput.enable = true;
      };
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.kdePackages.xdg-desktop-portal-kde
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common.default = ["kde" "gtk"];
        xdgOpenUsePortal = true;
      };
      home-manager.sharedModules = [inputs.plasma-manager.homeModules.plasma-manager];
      home-manager.users.${config.zelec-core.base.user.name} = {
        programs.plasma = {
          enable = true;
          shortcuts = {
            ksmserver."Lock Session" = ["Meta+L" "Screensaver"];
            kwin."Show Desktop" = "Meta+D";
            kwin."Switch One Desktop Down" = "Meta+Ctrl+Down";
            kwin."Switch One Desktop Up" = "Meta+Ctrl+Up";
            kwin."Switch One Desktop to the Left" = "Meta+Ctrl+Left";
            kwin."Switch One Desktop to the Right" = "Meta+Ctrl+Right";
            kwin."Switch Window Down" = "Meta+Alt+Down";
            kwin."Switch Window Left" = "Meta+Alt+Left";
            kwin."Switch Window Right" = "Meta+Alt+Right";
            kwin."Switch Window Up" = "Meta+Alt+Up";
            kwin."Walk Through Windows" = "Alt+Tab";
            kwin."Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
            kwin."Window Close" = "Alt+F4";
            kwin."Window Maximize" = "Meta+PgUp";
            kwin."Window Minimize" = "Meta+PgDown";
            kwin."Window Quick Tile Bottom" = "Meta+Down";
            kwin."Window Quick Tile Bottom Left" = [];
            kwin."Window Quick Tile Bottom Right" = [];
            kwin."Window Quick Tile Left" = "Meta+Left";
            kwin."Window Quick Tile Right" = "Meta+Right";
            kwin."Window Quick Tile Top" = "Meta+Up";
            kwin."Window Quick Tile Top Left" = [];
            kwin."Window Quick Tile Top Right" = [];
            kwin."Window to Next Screen" = "Meta+Shift+Right";
            kwin."Window to Previous Screen" = "Meta+Shift+Left";
          };
          configFile = {
            baloofilerc."Basic Settings".Indexing-Enabled = false;
            dolphinrc."KFileDialog Settings"."Places Icons Auto-resize" = false;
            dolphinrc."KFileDialog Settings"."Places Icons Static Size" = 22;
            kcminputrc.Mouse.cursorTheme = "breeze_cursors";
            kdeglobals.Icons.Theme = "Tela-dark";
            kiorc.Confirmations.ConfirmDelete = true;
            kiorc.Confirmations.ConfirmEmptyTrash = true;
            kiorc.Confirmations.ConfirmTrash = false;
            kscreenlockerrc.Daemon.LockGrace = 30;
            kscreenlockerrc.Daemon.Timeout = 30;
            kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".DynamicMode = "2";
            kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".Image = "file://${config.zelec-core.services.stylix.image}";
            kscreenlockerrc."Greeter/Wallpaper/org.kde.image/General".PreviewImage = "file://${config.zelec-core.services.stylix.image}";
            ksmserverrc.General.loginMode = "emptySession";
            plasma-localerc.Formats.LANG = "en_CA.UTF-8";
            plasma-localerc.Formats.LC_TIME = "en_GB.UTF-8";
            spectaclerc.Annotations.annotationToolType = 6;
            spectaclerc.Annotations.rectangleStrokeColor = "255,0,0";
            spectaclerc.General.launchAction = "UseLastUsedCapturemode";
            spectaclerc.ImageSave.translatedScreenshotsFolder = "Screenshots";
            spectaclerc.VideoSave.translatedScreencastsFolder = "Screencasts";
          };
          workspace = {
            lookAndFeel = "org.kde.breezedark.desktop";
            soundTheme = "ocean";
            colorScheme = "Gigavoltmod";
            iconTheme = "Tela-dark";
            theme = "breeze-dark";
            cursor = {
              cursorFeedback = "Bouncing";
              animationTime = 5;
              theme = "breeze_cursors";
              size = 24;
            };
            wallpaper = config.zelec-core.services.stylix.image;
          };
          panels = [
            {
              location = "bottom";
              hiding = "normalpanel";
              height = 50;
              alignment = "center";
              floating = true;
              screen = "all";
              widgets = [
                # org.kde.plasma.kickoff
                {
                  kickoff = {
                    sortAlphabetically = true;
                    icon = "nix-snowflake-white";
                  };
                }
                # org.kde.plasma.icontasks
                {
                  iconTasks = {
                    appearance.indicateAudioStreams = false;
                    behavior = {
                      grouping.clickAction = "showTextualList";
                      sortingMethod = "manually";
                      middleClickAction = "close";
                    };
                    launchers = [
                      "applications:firefox.desktop"
                      "applications:org.kde.dolphin.desktop"
                      "applications:org.kde.konsole.desktop"
                      "applications:codium.desktop"
                      "applications:vesktop.desktop"
                      "applications:org.signal.Signal.desktop"
                    ];
                  };
                }
                "org.kde.plasma.marginsseparator"
                "org.kde.plasma.systemtray"
                # org.kde.plasma.digitalclock
                {
                  digitalClock = {
                    calendar.firstDayOfWeek = "sunday";
                    time.format = "24h";
                    date.format = "isoDate";
                  };
                }
                "org.kde.plasma.showdesktop"
              ];
            }
          ];
        };
        programs.konsole = {
          enable = true;
          defaultProfile = "managed";
          profiles."managed" = {
            colorScheme = "WhiteOnBlack";
            font = {
              name = config.zelec-core.services.stylix.fonts.monospace.name;
              size = 9;
            };
            extraConfig = {
              "Scrolling"."HighlightScrolledLines" = false;
              "Terminal Features"."BlinkingCursorEnabled" = true;
            };
          };
        };
      };
    };
  };
}
