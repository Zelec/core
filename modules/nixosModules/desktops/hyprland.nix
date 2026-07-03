# Currently an experiment, not in use
{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.desktops-hyprland];
  };
  flake.nixosModules.desktops-hyprland = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.desktops.hyprland;
  in {
    options.zelec-core.desktops.hyprland = {
      enable = lib.mkEnableOption "Turns on Hyprland Desktop";
    };
    config = lib.mkIf cfg.enable {
      zelec-core = {
        services.pipewire.enable = lib.mkDefault true;
      };
      environment.systemPackages = with pkgs; [
        kdePackages.dolphin
        hyprpaper
        kitty
        waybar
        wofi
      ];
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      fonts.packages = with pkgs; [
        font-awesome
        nerd-fonts.jetbrains-mono
        dejavu_fonts
      ];
      services.gnome.gnome-keyring.enable = true;
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common.default = ["hyprland" "gtk"];
      };
      home-manager.users.${config.zelec-core.base.user.name} = {
        programs.waybar = {
          enable = true;
          # https://github.com/itsfoss/text-script-files/tree/master/config/waybar
          settings = {
            mainBar = {
              layer = "top";
              position = "bottom";
              spacing = 0;
              height = 34;
              modules-left = [
                "custom/logo"
                "hyprland/workspaces"
              ];
              modules-center = [
                "clock"
              ];
              modules-right = [
                "tray"
                "memory"
                "network"
                "wireplumber"
                "battery"
                "custom/power"
              ];
              "wlr/taskbar" = {
                format = "{icon}";
                on-click = "activate";
                on-click-right = "fullscreen";
                icon-theme = "WhiteSur";
                icon-size = 25;
                tooltip-format = "{title}";
              };
              "hyprland/workspaces" = {
                on-click = "activate";
                format = "{icon}";
                format-icons = {
                  "1" = "1";
                  "2" = "2";
                  "3" = "3";
                  "4" = "4";
                  "5" = "5";
                  "6" = "6";
                  "7" = "7";
                  "8" = "8";
                  "9" = "9";
                  default = "";
                  active = "󱓻";
                  urgent = "󱓻";
                };
                persistent_workspaces = {
                  "1" = [
                  ];
                  "2" = [
                  ];
                  "3" = [
                  ];
                  "4" = [
                  ];
                  "5" = [
                  ];
                };
              };
              memory = {
                interval = 5;
                format = "󰍛 {}%";
                max-length = 10;
              };
              tray = {
                spacing = 10;
              };
              clock = {
                tooltip-format = "{calendar}";
                format-alt = "  {:%a, %d %b %Y}";
                format = "  {:%H:%M}";
              };
              network = {
                format-wifi = "{icon}";
                format-icons = [
                  "󰤯"
                  "󰤟"
                  "󰤢"
                  "󰤥"
                  "󰤨"
                ];
                format-ethernet = "󰀂";
                format-alt = "󱛇";
                format-disconnected = "󰖪";
                tooltip-format-wifi = "{icon} {essid}\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
                tooltip-format-ethernet = "󰀂  {ifname}\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
                tooltip-format-disconnected = "Disconnected";
                on-click = "~/.config/rofi/wifi/wifi.sh &";
                on-click-right = "~/.config/rofi/wifi/wifinew.sh &";
                interval = 5;
                nospacing = 1;
              };
              wireplumber = {
                format = "{icon}";
                format-bluetooth = "󰂰";
                nospacing = 1;
                tooltip-format = "Volume : {volume}%";
                format-muted = "󰝟";
                format-icons = {
                  headphone = "";
                  default = [
                    "󰖀"
                    "󰕾"
                    ""
                  ];
                };
                on-click = "pamixer -t";
                scroll-step = 1;
              };
              "custom/logo" = {
                format = "  ";
                tooltip = false;
                on-click = "~/.config/rofi/launchers/misc/launcher.sh &";
              };
              battery = {
                format = "{capacity}% {icon}";
                format-icons = {
                  charging = [
                    "󰢜"
                    "󰂆"
                    "󰂇"
                    "󰂈"
                    "󰢝"
                    "󰂉"
                    "󰢞"
                    "󰂊"
                    "󰂋"
                    "󰂅"
                  ];
                  default = [
                    "󰁺"
                    "󰁻"
                    "󰁼"
                    "󰁽"
                    "󰁾"
                    "󰁿"
                    "󰂀"
                    "󰂁"
                    "󰂂"
                    "󰁹"
                  ];
                };
                format-full = "Charged ";
                interval = 5;
                states = {
                  warning = 20;
                  critical = 10;
                };
                tooltip = false;
              };
              "custom/power" = {
                format = "󰤆";
                tooltip = false;
                on-click = "~/.config/rofi/powermenu/type-2/powermenu.sh &";
              };
            };
          };
          style = ''
            * {
              border: none;
              border-radius: 0;
              min-height: 0;
              font-family: JetBrainsMono Nerd Font;
              font-size: 13px;
            }

            window#waybar {
              background-color: #181825;
              transition-property: background-color;
              transition-duration: 0.5s;
            }

            window#waybar.hidden {
              opacity: 0.5;
            }

            #workspaces {
              background-color: transparent;
            }

            #workspaces button {
              all: initial;
              /* Remove GTK theme values (waybar #1351) */
              min-width: 0;
              /* Fix weird spacing in materia (waybar #450) */
              box-shadow: inset 0 -3px transparent;
              /* Use box-shadow instead of border so the text isn't offset */
              padding: 6px 18px;
              margin: 6px 3px;
              border-radius: 4px;
              background-color: #1e1e2e;
              color: #cdd6f4;
            }

            #workspaces button.active {
              color: #1e1e2e;
              background-color: #cdd6f4;
            }

            #workspaces button:hover {
              box-shadow: inherit;
              text-shadow: inherit;
              color: #1e1e2e;
              background-color: #cdd6f4;
            }

            #workspaces button.urgent {
              background-color: #f38ba8;
            }

            #memory,
            #custom-power,
            #battery,
            #backlight,
            #wireplumber,
            #network,
            #clock,
            #tray {
              border-radius: 4px;
              margin: 6px 3px;
              padding: 6px 12px;
              background-color: #1e1e2e;
              color: #181825;
            }

            #custom-power {
              margin-right: 6px;
            }

            #custom-logo {
              padding-right: 7px;
              padding-left: 7px;
              margin-left: 5px;
              font-size: 15px;
              border-radius: 8px 0px 0px 8px;
              color: #5277c3;
            }

            #memory {
              background-color: #fab387;
            }

            #battery {
              background-color: #f38ba8;
            }

            #battery.warning,
            #battery.critical,
            #battery.urgent {
              background-color: #ff0000;
              color: #FFFF00;
            }

            #battery.charging {
              background-color: #a6e3a1;
              color: #181825;
            }

            #backlight {
              background-color: #fab387;
            }

            #wireplumber {
              background-color: #f9e2af;
            }

            #network {
              background-color: #94e2d5;
              padding-right: 17px;
            }

            #clock {
              font-family: JetBrainsMono Nerd Font;
              background-color: #cba6f7;
            }

            #custom-power {
              background-color: #f2cdcd;
            }


            tooltip {
              border-radius: 8px;
              padding: 15px;
              background-color: #131822;
            }

            tooltip label {
              padding: 5px;
              background-color: #131822;
            }
          '';
        };
        wayland.windowManager.hyprland = {
          configType = "hyprlang";
          enable = true;
          extraConfig = ''
            # This is an example Hyprland config file.
            # Refer to the wiki for more information.
            # https://wiki.hyprland.org/Configuring/

            # Please note not all available settings / options are set here.
            # For a full list, see the wiki

            # You can split this configuration into multiple files
            # Create your files separately and then link them to this file like this:
            # source = ~/.config/hypr/myColors.conf


            ################
            ### MONITORS ###
            ################

            # See https://wiki.hyprland.org/Configuring/Monitors/
            monitor=,preferred,auto,auto


            ###################
            ### MY PROGRAMS ###
            ###################

            # See https://wiki.hyprland.org/Configuring/Keywords/

            # Set programs that you use
            $browser = ${pkgs.firefox}/bin/firefox
            $terminal = ${pkgs.kitty}/bin/kitty
            $fileManager = ${pkgs.kdePackages.dolphin}/bin/dolphin
            $menu = ${pkgs.wofi}/bin/wofi --show drun


            #################
            ### AUTOSTART ###
            #################

            # Autostart necessary processes (like notifications daemons, status bars, etc.)
            # Or execute your favorite apps at launch like this:

            # exec-once = $terminal
            exec-once = nm-applet &
            exec-once = waybar & hyprpaper


            #############################
            ### ENVIRONMENT VARIABLES ###
            #############################

            # See https://wiki.hyprland.org/Configuring/Environment-variables/

            env = XCURSOR_SIZE,24
            env = HYPRCURSOR_SIZE,24


            #####################
            ### LOOK AND FEEL ###
            #####################

            # Refer to https://wiki.hyprland.org/Configuring/Variables/

            # https://wiki.hyprland.org/Configuring/Variables/#general
            general {
              gaps_in = 0
              gaps_out = 0

              border_size = 1

              # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
              col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
              col.inactive_border = rgba(595959aa)

              # Set to true enable resizing windows by clicking and dragging on borders and gaps
              resize_on_border = true

              # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
              allow_tearing = false

              layout = dwindle
            }

            # https://wiki.hyprland.org/Configuring/Variables/#decoration
            decoration {
              rounding = 2

              # Change transparency of focused and unfocused windows
              active_opacity = 1.0
              inactive_opacity = 1.0

              shadow {
                enabled = true
                range = 4
                render_power = 3
                color = rgba(1a1a1aee)
              }

              # https://wiki.hyprland.org/Configuring/Variables/#blur
              blur {
                enabled = true
                size = 3
                passes = 1

                vibrancy = 0.1696
              }
            }

            # https://wiki.hyprland.org/Configuring/Variables/#animations
            animations {
              enabled = yes

              # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

              bezier = easeOutQuint,0.23,1,0.32,1
              bezier = easeInOutCubic,0.65,0.05,0.36,1
              bezier = linear,0,0,1,1
              bezier = almostLinear,0.5,0.5,0.75,1.0
              bezier = quick,0.15,0,0.1,1

              animation = global, 1, 10, default
              animation = border, 1, 5.39, easeOutQuint
              animation = windows, 1, 4.79, easeOutQuint
              animation = windowsIn, 1, 4.1, easeOutQuint, popin 87%
              animation = windowsOut, 1, 1.49, linear, popin 87%
              animation = fadeIn, 1, 1.73, almostLinear
              animation = fadeOut, 1, 1.46, almostLinear
              animation = fade, 1, 3.03, quick
              animation = layers, 1, 3.81, easeOutQuint
              animation = layersIn, 1, 4, easeOutQuint, fade
              animation = layersOut, 1, 1.5, linear, fade
              animation = fadeLayersIn, 1, 1.79, almostLinear
              animation = fadeLayersOut, 1, 1.39, almostLinear
              animation = workspaces, 1, 1.94, almostLinear, fade
              animation = workspacesIn, 1, 1.21, almostLinear, fade
              animation = workspacesOut, 1, 1.94, almostLinear, fade
            }

            # Ref https://wiki.hyprland.org/Configuring/Workspace-Rules/
            # "Smart gaps" / "No gaps when only"
            # uncomment all if you wish to use that.
            # workspace = w[tv1], gapsout:0, gapsin:0
            # workspace = f[1], gapsout:0, gapsin:0
            # windowrulev2 = bordersize 0, floating:0, onworkspace:w[tv1]
            # windowrulev2 = rounding 0, floating:0, onworkspace:w[tv1]
            # windowrulev2 = bordersize 0, floating:0, onworkspace:f[1]
            # windowrulev2 = rounding 0, floating:0, onworkspace:f[1]

            # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
            dwindle {
              pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
              preserve_split = true # You probably want this
            }

            # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
            master {
              new_status = master
            }

            # https://wiki.hyprland.org/Configuring/Variables/#misc
            misc {
              force_default_wallpaper = -1 # Set to 0 or 1 to disable the anime mascot wallpapers
              disable_hyprland_logo = false # If true disables the random hyprland logo / anime girl background. :(
            }


            #############
            ### INPUT ###
            #############

            # https://wiki.hyprland.org/Configuring/Variables/#input
            input {
              kb_layout = us
              kb_variant =
              kb_model =
              kb_options =
              kb_rules =

              follow_mouse = 1

              sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

              touchpad {
                natural_scroll = false
              }
            }

            # https://wiki.hyprland.org/Configuring/Variables/#gestures
            gestures {
              workspace_swipe = false
            }

            # Example per-device config
            # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
            device {
              name = epic-mouse-v1
              sensitivity = -0.5
            }


            ###################
            ### KEYBINDINGS ###
            ###################

            # See https://wiki.hyprland.org/Configuring/Keywords/
            $mainMod = SUPER # Sets "Windows" key as main modifier

            bind = $mainMod, RETURN, exec, $terminal
            bind = $mainMod SHIFT, Q, killactive,
            bind = $mainMod, M, exit,
            bind = $mainMod, E, exec, $fileManager
            bind = $mainMod, V, togglefloating,
            bind = $mainMod, D, exec, $menu
            bind = $mainMod, P, pseudo, # dwindle
            bind = $mainMod, J, togglesplit, # dwindle
            bind = $mainMod, I, exec, $browser

            # Move focus with mainMod + arrow keys
            bind = $mainMod, left, movefocus, l
            bind = $mainMod, right, movefocus, r
            bind = $mainMod, up, movefocus, u
            bind = $mainMod, down, movefocus, d

            # Switch workspaces with mainMod + [0-9]
            bind = $mainMod, 1, workspace, 1
            bind = $mainMod, 2, workspace, 2
            bind = $mainMod, 3, workspace, 3
            bind = $mainMod, 4, workspace, 4
            bind = $mainMod, 5, workspace, 5
            bind = $mainMod, 6, workspace, 6
            bind = $mainMod, 7, workspace, 7
            bind = $mainMod, 8, workspace, 8
            bind = $mainMod, 9, workspace, 9
            bind = $mainMod, 0, workspace, 10

            # Move active window to a workspace with mainMod + SHIFT + [0-9]
            bind = $mainMod SHIFT, 1, movetoworkspacesilent, 1
            bind = $mainMod SHIFT, 2, movetoworkspacesilent, 2
            bind = $mainMod SHIFT, 3, movetoworkspacesilent, 3
            bind = $mainMod SHIFT, 4, movetoworkspacesilent, 4
            bind = $mainMod SHIFT, 5, movetoworkspacesilent, 5
            bind = $mainMod SHIFT, 6, movetoworkspacesilent, 6
            bind = $mainMod SHIFT, 7, movetoworkspacesilent, 7
            bind = $mainMod SHIFT, 8, movetoworkspacesilent, 8
            bind = $mainMod SHIFT, 9, movetoworkspacesilent, 9
            bind = $mainMod SHIFT, 0, movetoworkspacesilent, 10

            # Example special workspace (scratchpad)
            bind = $mainMod, S, togglespecialworkspace, magic
            bind = $mainMod SHIFT, S, movetoworkspacesilent, special:magic

            # Scroll through existing workspaces with mainMod + scroll
            bind = $mainMod, mouse_down, workspace, e+1
            bind = $mainMod, mouse_up, workspace, e-1

            # Move/resize windows with mainMod + LMB/RMB and dragging
            bindm = $mainMod, mouse:272, movewindow
            bindm = $mainMod, mouse:273, resizewindow

            # Laptop multimedia keys for volume and LCD brightness
            bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
            bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
            bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            bindel = ,XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 10%+
            bindel = ,XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 10%-

            # Requires playerctl
            bindl = , XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next
            bindl = , XF86AudioPause, exec, ${pkgs.playerctl}/bin/playerctl play-pause
            bindl = , XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause
            bindl = , XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous

            ##############################
            ### WINDOWS AND WORKSPACES ###
            ##############################

            # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
            # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

            # Example windowrule v1
            # windowrule = float, ^(kitty)$

            # Example windowrule v2
            # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$

            # Ignore maximize requests from apps. You'll probably like this.
            windowrulev2 = suppressevent maximize, class:.*

            # Fix some dragging issues with XWayland
            windowrulev2 = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0

          '';
        };
      };
    };
  };
}
