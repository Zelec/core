# Default NixOS Configuration and junk
{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.base-nix-common = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.base;
  in {
    options.zelec-core.base = {
      nix-common.enable = lib.mkOption {
        description = "Turns on nix-tweaks options";
        type = lib.types.bool;
        default = cfgRoot.autoEnable;
      };
    };
    config = let
      defaultOverlays = [
        inputs.copyparty.overlays.default
        inputs.nix-vscode-extensions.overlays.default
        inputs.nur.overlays.default
        inputs.nvidia-patch.overlays.default
      ];
      baseNixPkgConfig = {
        allowUnfree = true;
        permittedInsecurePackages = [
          # Ventoy is marked as insecure due to it's licensing problems and blob use
          inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.ventoy-full-qt.name
          # Vesktop breakage
          "pnpm-10.29.2"
        ];
      };
    in
      lib.mkIf cfg.enable (lib.mkMerge [
        {
          nixpkgs = {
            config = baseNixPkgConfig;
            overlays =
              defaultOverlays
              ++ [
                (final: prev: {
                  unstable = import inputs.nixpkgs-unstable {
                    system = prev.stdenv.hostPlatform.system;
                    config = baseNixPkgConfig;
                    overlays = defaultOverlays;
                  };
                })
              ];
          };
          users.mutableUsers = false;
          home-manager.useGlobalPkgs = true;
          fonts.enableDefaultPackages = true;
          i18n = {
            defaultLocale = "en_CA.UTF-8";
            supportedLocales = [
              "en_CA.UTF-8/UTF-8"
              "en_US.UTF-8/UTF-8"
              "en_GB.UTF-8/UTF-8"
            ];
          };
          time.timeZone = cfg.timeZone;
          nix = {
            settings = {
              experimental-features = ["nix-command" "flakes"];
              warn-dirty = false;
              trusted-users = [
                "root"
                cfg.user.name
              ];
              allowed-users = [
                "root"
                cfg.user.name
              ];
              substituters = [
                "https://cache.nixos.org/"
                "https://nix-community.cachix.org"
              ];
              trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
            };
            # Pin nixpkgs to the flake input for nix-shell
            nixPath = ["nixpkgs=${inputs.nixpkgs}"];
            # Automatic Garbage Collection of older NixOS Generations
            gc = {
              automatic = true;
              dates = "daily";
              options = "--delete-older-than 15d";
            };
            # Automatic consolidation of the nix store
            optimise = {
              automatic = true;
              dates = [
                "03:45"
              ];
            };
          };
          programs = {
            bash.completion.enable = true;
            dconf.enable = true;
            nix-ld = {
              enable = true;
              package = pkgs.nix-ld;
              libraries = with pkgs; [
                icu
                icu.dev
                sdl3
              ];
            };
          };
          environment.systemPackages = with pkgs; [
            nixd
          ];
          networking.firewall.enable = lib.mkDefault false;
          security.polkit.enable = true;
        }
        (lib.mkIf (config.services.displayManager.enable) {
          programs.ssh.startAgent = false;
          services.gnome.gcr-ssh-agent.enable = true;
        })
        (lib.mkIf (! config.services.displayManager.enable) {
          programs.ssh.startAgent = true;
          services.gnome.gcr-ssh-agent.enable = false;
        })
      ]);
  };
}
