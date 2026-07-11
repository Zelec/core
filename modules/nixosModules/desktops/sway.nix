{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.desktops-sway];
  };
  flake.nixosModules.desktops-sway = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.desktops.sway;
  in {
    options.zelec-core.desktops.sway = {
      enable = lib.mkEnableOption "Turns on Hyprland Desktop";
    };
    config = lib.mkIf cfg.enable {
      zelec-core = {
        services.pipewire.enable = lib.mkDefault true;
      };
      environment.systemPackages = with pkgs; [
        grim
        mako
        pulseaudio
        slurp
        waylock
        wl-clipboard
      ];
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      fonts.packages = with pkgs; [
        dejavu_fonts
        font-awesome
        nerd-fonts.jetbrains-mono
        noto-fonts-color-emoji
        source-code-pro
      ];
      services.gnome.gnome-keyring.enable = true;
      programs.sway = {
        enable = true;
        wrapperFeatures.gtk = true;
      };
      services.displayManager = {
        defaultSession = "sway";
        sddm.enable = true;
        sddm.wayland.enable = true;
        autoLogin.enable = true;
        autoLogin.user = config.zelec-core.base.user.name;
      };
      xdg.portal = {
        enable = true;
        # Use the wlr portal for wlroots-specific features and GTK as a fallback
        extraPortals = [
          pkgs.xdg-desktop-portal-wlr
          pkgs.xdg-desktop-portal-gtk
        ];
        # Use GTK as the common default since wlr is not as featureful outside of screen capture
        config.common.default = ["gtk"];
        # Explicitly use wlr for screen capture interfaces
        config.sway = {
          "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
          "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
        };
      };
      home-manager.users.${config.zelec-core.base.user.name} = {
        programs.swaylock = {
          enable = true;
        };
        services.swayidle = {
          enable = true;
          events = {
            "before-sleep" = "${pkgs.swaylock}/bin/swaylock -f";
            "lock" = "${pkgs.swaylock}/bin/swaylock -f";
          };
          timeouts = [
            {
              timeout = 360;
              command = "${pkgs.swaylock}/bin/swaylock -f";
            }
          ];
        };
        programs.waybar = {
          enable = true;
          # https://github.com/cjbassi/config/tree/master/.config/waybar
          # https://github.com/cjbassi/config/tree/ac1428769aa85becc962bfb9bfcfe879cad5f9f6/.config/waybar
          # https://json-to-nix.pages.dev/
          settings = {
            mainBar = {
              layer = "top";
              position = "bottom";
              modules-left = [
                "sway/workspaces"
                "custom/right-arrow-dark"
              ];
              modules-center = [
                "custom/left-arrow-dark"
                "clock#1"
                "custom/left-arrow-light"
                "custom/left-arrow-dark"
                "clock#2"
                "custom/right-arrow-dark"
                "custom/right-arrow-light"
                "clock#3"
                "custom/right-arrow-dark"
              ];
              modules-right = [
                "custom/left-arrow-dark"
                "pulseaudio"
                "custom/left-arrow-light"
                "custom/left-arrow-dark"
                "memory"
                "custom/left-arrow-light"
                "custom/left-arrow-dark"
                "cpu"
                "custom/left-arrow-light"
                "custom/left-arrow-dark"
                "battery"
                "custom/left-arrow-light"
                "custom/left-arrow-dark"
                "disk"
                "custom/left-arrow-light"
                "custom/left-arrow-dark"
                "idle_inhibitor"
                "custom/left-arrow-light"
                "custom/left-arrow-dark"
                "tray"
              ];
              "custom/left-arrow-dark" = {
                format = "";
                tooltip = false;
              };
              "custom/left-arrow-light" = {
                format = "";
                tooltip = false;
              };
              "custom/right-arrow-dark" = {
                format = "";
                tooltip = false;
              };
              "custom/right-arrow-light" = {
                format = "";
                tooltip = false;
              };
              "sway/workspaces" = {
                disable-scroll = true;
                format = "{name}";
              };
              "clock#1" = {
                format = "{:%a}";
                tooltip = false;
              };
              "clock#2" = {
                format = "{:%H:%M}";
                tooltip = false;
              };
              "clock#3" = {
                format = "{:%m-%d}";
                tooltip = false;
              };
              pulseaudio = {
                format = "{icon} {volume:2}%";
                format-bluetooth = "{icon}  {volume}%";
                format-muted = "MUTE";
                format-icons = {
                  headphones = "";
                  default = [
                    ""
                    ""
                  ];
                };
                scroll-step = 5;
                on-click = "pamixer -t";
                on-click-right = "pavucontrol";
              };
              memory = {
                interval = 5;
                format = "Mem {}%";
              };
              cpu = {
                interval = 5;
                format = "CPU {usage:2}%";
              };
              battery = {
                states = {
                  good = 95;
                  warning = 30;
                  critical = 15;
                };
                format = "{icon} {capacity}%";
                format-icons = [
                  ""
                  ""
                  ""
                  ""
                  ""
                ];
              };
              disk = {
                interval = 5;
                format = "Disk {percentage_used:2}%";
                path = "/";
              };
              idle_inhibitor = {
                format = "{icon}";
                format-icons = {
                  activated = "";
                  deactivated = "";
                };
                start-activated = false;
                tooltip = true;
                tooltip-format = "Idle Inhibitor: {state}";
              };
              tray = {
                icon-size = 20;
              };
            };
          };
          style = ''
            * {
              font-size: 20px;
              font-family: monospace;
            }

            window#waybar {
              background: #292b2e;
              color: #fdf6e3;
            }

            #custom-right-arrow-dark,
            #custom-left-arrow-dark {
              color: #1a1a1a;
            }
            #custom-right-arrow-light,
            #custom-left-arrow-light {
              color: #292b2e;
              background: #1a1a1a;
            }

            #workspaces,
            #clock.1,
            #clock.2,
            #clock.3,
            #pulseaudio,
            #memory,
            #cpu,
            #battery,
            #disk,
            #idle_inhibitor,
            #tray {
              background: #1a1a1a;
            }

            #workspaces button {
              padding: 0 2px;
              color: #fdf6e3;
            }
            #workspaces button.focused {
              color: #00aaff;
            }
            #workspaces button:hover {
              box-shadow: inherit;
              text-shadow: inherit;
            }
            #workspaces button:hover {
              background: #1a1a1a;
              border: #1a1a1a;
              padding: 0 3px;
            }

            #pulseaudio {
              color: #00aaff;
            }
            #memory {
              color: #00aaff;
            }
            #cpu {
              color: #00aaff;
            }
            #battery {
              color: #00aaff;
            }
            #disk {
              color: #00aaff;
            }
            #idle_inhibitor {
              color: #00aaff;
            }

            #clock,
            #pulseaudio,
            #memory,
            #cpu,
            #battery,
            #disk {
              padding: 0 10px;
            }
          '';
        };
        wayland.windowManager.sway = {
          enable = true;
          xwayland = true;
          config = {
            modifier = "Mod4";
            # Use kitty as default terminal
            #terminal = "kitty";
            defaultWorkspace = "workspace number 1";
            startup = [
              # Launch Firefox on start
              # {command = "firefox";}
            ];
            bars = [
              {
                command = "${pkgs.waybar}/bin/waybar";
              }
            ];
            keybindings = let
              mod = config.home-manager.users.${config.zelec-core.base.user.name}.wayland.windowManager.sway.config.modifier;
            in
              lib.mkOptionDefault {
                # Browser
                "${mod}+i" = ''exec ${pkgs.firefox}/bin/firefox'';

                # Brightness
                "XF86MonBrightnessDown" = ''exec ${pkgs.brightnessctl}/bin/brightnessctl set -10'';
                "XF86MonBrightnessUp" = ''exec ${pkgs.brightnessctl}/bin/brightnessctl set +10'';

                # Volume
                "XF86AudioRaiseVolume" = ''exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +1%'';
                "XF86AudioLowerVolume" = ''exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -1%'';
                "XF86AudioMute" = ''exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle'';
              };
          };
        };
      };
    };
  };
}
