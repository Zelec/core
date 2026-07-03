{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-vscodium];
  };
  flake.nixosModules.programs-vscodium = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.vscodium;
  in {
    options.zelec-core.programs.vscodium = {
      enable = lib.mkEnableOption "Enables vscodium";
    };
    config = lib.mkIf cfg.enable {
      home-manager.users.${config.zelec-core.base.user.name} = {...}: {
        # Simple package rename to redirect all calls for code to codium
        # Muscle memory be dammed
        home.packages = [
          (pkgs.writeShellScriptBin "code" ''
            exec ${pkgs.unstable.vscodium}/bin/codium "$@"
          '')
        ];
        programs.vscodium = {
          enable = true;
          package = pkgs.unstable.vscodium;
          profiles.default = {
            extensions = with pkgs.unstable; [
              open-vsx.jeanp413.open-remote-ssh
              open-vsx.jnoortheen.nix-ide
              open-vsx.signageos.signageos-vscode-sops
              open-vsx.vscode-icons-team.vscode-icons
              vscode-marketplace.ms-vscode-remote.remote-containers
              vscode-marketplace.ms-vscode-remote.remote-ssh-edit
            ];
            userSettings = {
              "editor.indentSize" = "tabSize";
              "editor.tabSize" = 2;
              "http.systemCertificatesNode" = true;
              "git.autofetch" = true;
              "nix.enableLanguageServer" = true;
              "nix.serverPath" = "nixd";
              "nix.serverSettings" = {
                "nixd" = {
                  "formatting" = {
                    "command" = ["alejandra"];
                  };
                };
              };
              "remote.autoForwardPortsSource" = "hybrid";
              "terminal.integrated.stickyScroll.enabled" = false;
              "workbench.iconTheme" = "vscode-icons";
            };
          };
        };
      };
    };
  };
}
