# The stuff here in the base modules folder was based off of Goxore's nixconf flake
# Or as he is known on youtube Vimjoyer
# https://github.com/Goxore/nixconf/blob/8065ed5479d78b716c9a45057ff7742f31e70b1d/modules/nixosModules/base/user.nix
{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.base-user = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.base.user;
  in {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];
    options.zelec-core.base.user = {
      enable = lib.mkOption {
        description = "Enables base user creation";
        type = lib.types.bool;
        default = cfgRoot.autoEnable;
      };
      name = lib.mkOption {
        description = "User name for the user account";
        type = lib.types.str;
        default = "zelec";
      };
      description = lib.mkOption {
        description = "Display name for the user account";
        type = lib.types.str;
        default = "Isaac Towns";
      };
      email = lib.mkOption {
        description = "Email address for user account";
        type = lib.types.str;
        default = "Isaac@timeguard.ca";
      };
      # Required
      hashedPasswordFile = lib.mkOption {
        description = "Path to password hash for the user, required";
        type = lib.types.str;
      };
      face = lib.mkOption {
        description = "Image file for user's profile in display manager contexts";
        type = lib.types.nullOr lib.types.path;
        default = ./face.png;
      };
    };
    config = lib.mkIf cfg.enable {
      users.users.${cfg.name} = {
        linger = true;
        isNormalUser = true;
        description = cfg.description;
        extraGroups = [
          "networkmanager"
          "wheel"
          "docker"
          "libvirtd"
          "kvm"
          "video"
          "cdrom"
          "dialout"
          "tss"
        ];
        hashedPasswordFile = cfg.hashedPasswordFile;
        packages = with pkgs; [
        ];
      };
      # Homemanager Stuff
      home-manager.useGlobalPkgs = true;
      # Move & Overwrite file collisions
      home-manager.backupFileExtension = "hm-bak";
      home-manager.overwriteBackup = true;
      home-manager.users.${cfg.name} = {
        home.stateVersion = "24.11";

        home.username = cfg.name;
        home.homeDirectory = "/home/${cfg.name}";

        home.packages = with pkgs; [
        ];

        home.file = let
          # To help simplify path typing for libvirt
          # Full path example "/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd"
          edk2f = "/run/libvirt/nix-ovmf/edk2";
        in {
          # I have no clue where I found this and why it's here
          # # Helps to fix an nvidia default optimzation that causes flickering, crashing, and tearing
          # ".nv/nvidia-application-profiles-rc".text = ''
          #   {
          #       "rules": [
          #           {
          #               "pattern": {
          #                   "feature": "dso",
          #                   "matches": "libGL.so.1"
          #               },
          #               "profile": "openGL_fix"
          #           }
          #       ],
          #       "profiles": [
          #           {
          #               "name": "openGL_fix",
          #               "settings": [
          #                   {
          #                       "key": "GLThreadedOptimizations",
          #                       "value": false
          #                   }
          #               ]
          #           }
          #       ]
          #   }
          # '';
          # https://nixos.wiki/wiki/Libvirt
          ".config/libvirt/qemu.conf".text = ''
            nvram = [ "${edk2f}-aarch64-code.fd:${edk2f}-arm-vars.fd", "${edk2f}-arm-code.fd:${edk2f}-arm-vars.fd", "${edk2f}-x86_64-secure-code.fd:${edk2f}-i386-vars.fd", "${edk2f}-x86_64-code.fd:${edk2f}-i386-vars.fd", "${edk2f}-i386-secure-code.fd:${edk2f}-i386-vars.fd", "${edk2f}-i386-code.fd:${edk2f}-i386-vars.fd" ]
          '';
          # Profile icon for display managers
          ".face".source = cfg.face;
          ".face.icon".source = cfg.face;
        };
        home.sessionVariables = {
          EDITOR = "nano";
        };
        dconf.settings = {
          "org/virt-manager/virt-manager/connections" = {
            autoconnect = ["qemu:///system"];
            uris = [
              "qemu:///system"
              "qemu+ssh://${cfg.name}@Amethyst.timeguard.ca/system"
              "qemu+ssh://${cfg.name}@Lapis.timeguard.ca/system"
              "qemu+ssh://${cfg.name}@Pearl.timeguard.ca/system"
              "qemu+ssh://${cfg.name}@TimeDial.timeguard.ca/system"
            ];
          };
          "org/virt-manager/virt-manager" = {
            "system-tray" = true;
            "xmleditor-enabled" = true;
          };
          "org/virt-manager/virt-manager/console" = {
            "resize-guest" = 1;
          };
        };
        programs = {
          home-manager.enable = true;
          bash = {
            enable = true;
            shellAliases = {
              oxker = "docker pull docker.io/mrjackwills/oxker:latest && docker run --name oxker -it --rm -v /var/run/docker.sock:/var/run/docker.sock:ro docker.io/mrjackwills/oxker:latest";
              ctop = "docker pull quay.io/vektorlab/ctop:latest && docker run --name ctop -it --rm -v /var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop:latest";
              dive = "docker pull docker.io/wagoodman/dive:latest && docker run --name dive -it --rm -v /var/run/docker.sock:/var/run/docker.sock docker.io/wagoodman/dive:latest";
            };
            sessionVariables = {
              EDITOR = "nano";
              # Fails to set if set in here
              # PS1 = ''\[\e[${ps1MainColour}\][\u@\h\[\e[${ps1DefaultColour}\] \[\e[${ps1DefaultColour}\]\W\[\e[${ps1MainColour}\]]\$\[\e[${ps1DefaultColour}\] '';
            };
            # Had to move PS1 in here to make it work
            bashrcExtra = let
              # PS1 prompt
              # Cyan
              ps1MainColour = "38;5;51m";
              # White
              ps1DefaultColour = "0m";
            in ''
              PS1='\[\e[${ps1MainColour}\][\u@\h\[\e[${ps1DefaultColour}\] \[\e[${ps1DefaultColour}\]\W\[\e[${ps1MainColour}\]]\$\[\e[${ps1DefaultColour}\] ';
              # Gitignore creator
              gi() {
                curl -sL "https://www.gitignore.io/api/$@"
              }

              # Container upgrade via watchtower
              watchtower() {
                if [ ! -f "$HOME/.docker/config.json" ]; then
                  mkdir -p "$HOME/.docker"
                  touch "$HOME/.docker/config.json"
                  echo "{}" >> "$HOME/.docker/config.json"
                fi
                docker pull docker.io/nickfedor/watchtower:latest
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$HOME/.docker/config.json":/config.json:ro docker.io/nickfedor/watchtower:latest --run-once
              }
            '';
          };
          direnv = {
            enable = true;
            enableBashIntegration = true;
            nix-direnv.enable = true;
          };
          git = {
            enable = true;
            lfs.enable = true;
            settings = {
              user = {
                name = cfg.description;
                email = cfg.email;
              };
              init = {
                defaultBranch = "main";
              };
            };
          };
        };
      };
    };
  };
}
