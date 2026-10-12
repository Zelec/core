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
      enableAutoLogin = lib.mkOption {
        description = "Enables autologin via SDDM";
        type = lib.types.bool;
        default = cfg.enable;
      };
      forceLockOnFirstLogin = lib.mkEnableOption "Enables little auto-login script to auto lock the session when signing in the first time (Helpful when autologin is turned on)";
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
          autoLogin = lib.mkIf cfg.enableAutoLogin {
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
        xdg.configFile."autostart/lock-on-startup.desktop" = lib.mkIf cfg.forceLockOnFirstLogin {
          text = ''
            [Desktop Entry]
            Type=Application
            Name=Lock Session on Startup (Nix Controlled)
            Exec=loginctl lock-session
            X-KDE-autostart-condition=ksmserver
          '';
        };
        programs.plasma = {
          enable = true;
          shortcuts = {
            ksmserver."Lock Session" = ["Meta+L" "Screensaver"];
            kwin = {
              "Show Desktop" = "Meta+D";
              "Switch One Desktop Down" = "Meta+Ctrl+Down";
              "Switch One Desktop Up" = "Meta+Ctrl+Up";
              "Switch One Desktop to the Left" = "Meta+Ctrl+Left";
              "Switch One Desktop to the Right" = "Meta+Ctrl+Right";
              "Switch Window Down" = "Meta+Alt+Down";
              "Switch Window Left" = "Meta+Alt+Left";
              "Switch Window Right" = "Meta+Alt+Right";
              "Switch Window Up" = "Meta+Alt+Up";
              "Walk Through Windows" = "Alt+Tab";
              "Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
              "Window Close" = "Alt+F4";
              "Window Maximize" = "Meta+PgUp";
              "Window Minimize" = "Meta+PgDown";
              "Window Quick Tile Bottom" = "Meta+Down";
              "Window Quick Tile Bottom Left" = [];
              "Window Quick Tile Bottom Right" = [];
              "Window Quick Tile Left" = "Meta+Left";
              "Window Quick Tile Right" = "Meta+Right";
              "Window Quick Tile Top" = "Meta+Up";
              "Window Quick Tile Top Left" = [];
              "Window Quick Tile Top Right" = [];
              "Window to Next Screen" = "Meta+Shift+Right";
              "Window to Previous Screen" = "Meta+Shift+Left";
            };
          };
          configFile = {
            baloofilerc."Basic Settings".Indexing-Enabled = false;
            dolphinrc = {
              "KFileDialog Settings"."Places Icons Auto-resize" = false;
              "KFileDialog Settings"."Places Icons Static Size" = 22;
            };
            kcminputrc.Mouse.cursorTheme = "breeze_cursors";
            kdeglobals.Icons.Theme = "Tela-dark";
            kiorc = {
              Confirmations = {
                ConfirmDelete = true;
                ConfirmEmptyTrash = true;
                ConfirmTrash = false;
              };
            };
            kscreenlockerrc = {
              "Greeter/Wallpaper/org.kde.image/General".DynamicMode = "2";
              "Greeter/Wallpaper/org.kde.image/General".Image = "file://${config.zelec-core.services.stylix.image}";
              "Greeter/Wallpaper/org.kde.image/General".PreviewImage = "file://${config.zelec-core.services.stylix.image}";
              Daemon.LockGrace = 30;
              Daemon.Timeout = 30;
            };
            ksmserverrc.General.loginMode = "emptySession";
            kwinrc.Effect-overview.BorderActivate = 9;
            plasma-localerc = {
              Formats.LANG = "en_CA.UTF-8";
              Formats.LC_TIME = "en_GB.UTF-8";
            };
            spectaclerc = {
              Annotations.annotationToolType = 6;
              Annotations.rectangleStrokeColor = "255,0,0";
              General.launchAction = "UseLastUsedCapturemode";
              ImageSave.translatedScreenshotsFolder = "Screenshots";
              VideoSave.translatedScreencastsFolder = "Screencasts";
            };
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
