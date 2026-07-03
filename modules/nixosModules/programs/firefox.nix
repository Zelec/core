{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-firefox];
  };
  flake.nixosModules.programs-firefox = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.firefox;
  in {
    options.zelec-core.programs.firefox = {
      enable = lib.mkEnableOption "Enables firefox";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.wrapFirefox (pkgs.firefox-unwrapped.override {pipewireSupport = true;}) {};
        example = pkgs.firefox;
      };
      managedProfileName = lib.mkOption {
        type = lib.types.str;
        default = "managed";
        example = "managed";
      };
      bookmarks = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [{}];
        example = [
          {
            name = "Bookmarks Toolbar";
            toolbar = true;
            bookmarks = [
              {
                name = "Folder 1";
                bookmarks = [
                  {
                    name = "Site 1";
                    url = "https://site1/";
                  }
                  {
                    name = "Site2";
                    url = "https://site2/";
                  }
                  {
                    name = "Subfolder 1";
                    bookmarks = [
                      {
                        name = "Site 1";
                        url = "https://site1/";
                      }
                      {
                        name = "Site2";
                        url = "https://site2/";
                      }
                    ];
                  }
                  {
                    name = "Subfolder 1";
                    bookmarks = [
                      {
                        name = "Site 1";
                        url = "https://site1/";
                      }
                      {
                        name = "Site2";
                        url = "https://site2/";
                      }
                    ];
                  }
                ];
              }
            ];
          }
        ];
      };
    };
    config = lib.mkIf cfg.enable {
      environment.sessionVariables.DEFAULT_BROWSER = lib.getExe cfg.package;
      home-manager.users.${config.zelec-core.base.user.name} = {
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "text/html" = "firefox.desktop";
            "x-scheme-handler/http" = "firefox.desktop";
            "x-scheme-handler/https" = "firefox.desktop";
            "x-scheme-handler/about" = "firefox.desktop";
            "x-scheme-handler/unknown" = "firefox.desktop";
          };
        };
        stylix.targets.firefox.profileNames = [cfg.managedProfileName];
        programs.firefox = {
          enable = true;
          package = cfg.package;
          # because home manager state is less than 26.05 I have to define the config path to silence the new warning
          configPath = ".mozilla/firefox";
          policies = {
            DNSOverHTTPS.Enabled = false;
            PasswordManagerEnabled = false;
            DisableFirefoxStudies = true;
            DisableTelemetry = true;
            GenerativeAI.Enabled = false;
            FirefoxHome = {
              SponsoredStories = false;
              SponsoredTopSites = false;
              Stories = false;
            };
            ExtensionSettings = {
              # uBlock Origin
              "uBlock0@raymondhill.net".settings = {
                private_browsing = true;
              };
              # DarkReader
              "addon@darkreader.org".settings = {
                private_browsing = true;
              };
              # Stylus
              "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}".settings = {
                private_browsing = true;
              };
              # Bitwarden
              "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
                private_browsing = true;
              };
              # Indie Wiki Buddy
              "{cb31ec5d-c49a-4e5a-b240-16c767444f62}" = {
                private_browsing = true;
              };
            };
            "3rdparty" = {
              Extensions = {
                # Bitwarden
                "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
                  environment = {
                    base = "https://vault.timeguard.ca";
                  };
                };
              };
            };
          };
          profiles.${cfg.managedProfileName} = {
            isDefault = true;
            search = {
              default = "ddg";
              order = ["ddg"];
              force = true;
            };
            extensions = {
              force = true;
              packages = with pkgs.nur.repos.rycee.firefox-addons; [
                bitwarden
                darkreader
                indie-wiki-buddy
                plasma-integration
                stylus
                ublock-origin
              ];
            };
            bookmarks = {
              force = true;
              settings = cfg.bookmarks;
            };
            settings = {
              # Makes extensions work better
              "extensions.autoDisableScopes" = 0;
              "extensions.update.autoUpdateDefault" = false;
              "extensions.update.enabled" = false;
              # New tab settings for removing ads
              "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
              "browser.newtabpage.activity-stream.feeds.topsites" = false;
              "browser.newtabpage.activity-stream.newtabLayouts.variant-b" = true;
              "browser.newtabpage.activity-stream.weather.temperatureUnits" = "c";
              # Canadian search region
              "browser.search.region" = "CA";
              # Always show the bookmark bar
              "browser.toolbars.bookmarks.visibility" = "always";
              # Forces titlebar to be normal on KDE so the minimize, maximize, and close buttons exist
              "browser.tabs.inTitlebar" = 0;
              # Basically defaults, however this removes the import bookmarks button from bookmarks bar
              "browser.uiCustomization.state" = "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[\"plasma-browser-integration_kde_org-browser-action\"],\"nav-bar\":[\"back-button\",\"forward-button\",\"stop-reload-button\",\"customizableui-special-spring1\",\"vertical-spacer\",\"urlbar-container\",\"customizableui-special-spring2\",\"save-to-pocket-button\",\"downloads-button\",\"fxa-toolbar-menu-button\",\"unified-extensions-button\",\"_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action\",\"ublock0_raymondhill_net-browser-action\",\"addon_darkreader_org-browser-action\",\"_7a7a4a92-a2a0-41d1-9fd7-1e92480d612d_-browser-action\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"firefox-view-button\",\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"vertical-tabs\":[],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"save-to-pocket-button\",\"developer-button\",\"_7a7a4a92-a2a0-41d1-9fd7-1e92480d612d_-browser-action\",\"addon_darkreader_org-browser-action\",\"_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action\",\"ublock0_raymondhill_net-browser-action\",\"plasma-browser-integration_kde_org-browser-action\",\"screenshot-button\"],\"dirtyAreaCache\":[\"nav-bar\",\"vertical-tabs\",\"PersonalToolbar\",\"toolbar-menubar\",\"TabsToolbar\",\"unified-extensions-area\"],\"currentVersion\":22,\"newElementCount\":4}";
              # Custom sync server, not in use anymore due to this Nix config
              "identity.sync.tokenserver.uri" = "https://firefox-sync.timeguard.ca/token/1.0/sync/1.5";
              # If for some reason DNS over HTTPS/TLS is enabled, don't use it for these domain names
              "network.trr.excluded-domains" = "tgdev.ca,tgdev.net,timeguard.ca";
            };
          };
        };
      };
    };
  };
}
