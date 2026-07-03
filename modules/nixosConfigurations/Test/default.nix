{
  inputs,
  self,
  lib,
  ...
}: {
  # Multi system loader so I can test loading things against both x86_64 and aarch64
  flake.nixosConfigurations = let
    mkSystemTests = system: {
      "Test-kde-${system}" = inputs.nixpkgs.lib.nixosSystem {
        modules = with self.nixosModules; [
          hosts-Test-base
          hosts-Test-kde
          {nixpkgs.hostPlatform = system;}
        ];
      };
      "Test-hyprland-${system}" = inputs.nixpkgs.lib.nixosSystem {
        modules = with self.nixosModules; [
          hosts-Test-base
          hosts-Test-hyprland
          {nixpkgs.hostPlatform = system;}
        ];
      };
      "Test-sway-${system}" = inputs.nixpkgs.lib.nixosSystem {
        modules = with self.nixosModules; [
          hosts-Test-base
          hosts-Test-sway
          {nixpkgs.hostPlatform = system;}
        ];
      };
    };
    allTests = map mkSystemTests ["x86_64-linux" "aarch64-linux"];
  in
    lib.foldr (a: b: a // b) {} allTests;
  flake.nixosModules.hosts-Test-kde = {
    zelec-core.desktops.kde.enable = true;
  };
  flake.nixosModules.hosts-Test-hyprland = {
    zelec-core.desktops.hyprland.enable = true;
  };
  flake.nixosModules.hosts-Test-sway = {
    zelec-core.desktops.sway.enable = false;
  };
  flake.nixosModules.hosts-Test-base = {
    config,
    lib,
    pkgs,
    ...
  }: let
    # Simple boolean to disable certain test options on non x86 platforms
    isX86 = pkgs.stdenv.hostPlatform.isx86_64;
  in {
    imports = [self.nixosModules.default];
    zelec-core = {
      autoEnable = true;
      base = {
        user = {
          hashedPasswordFile = builtins.readFile (pkgs.runCommand "test-password-hash" {} ''
            echo -n "Pass2345" | ${pkgs.mkpasswd}/bin/mkpasswd -m sha-512 --stdin > $out
          '');
        };
      };
      common = {
        server-host.enable = true;
      };
      hardware = {
        bluetooth.enable = true;
        nvidia = {
          enable = isX86;
          enablePatch = isX86;
        };
      };
      networking = {
        nm-plus-resolved.enable = true;
      };
      programs = {
        adb.enable = true;
        chromium.enable = true;
        common-cli.enable = true;
        common-gui.enable = true;
        discord.enable = true;
        firefox = {
          enable = true;
          managedProfileName = "managed";
        };
        hunspell.enable = true;
        k3b.enable = true;
        neovim.enable = true;
        obs = {
          enable = true;
          enableCUDA = isX86;
        };
        sdr.enable = true;
        steam = {enable = isX86;};
        vscodium.enable = true;
        wine = {enable = isX86;};
      };
      services = {
        beszel-agent = {
          enable = true;
          envFilePath = toString pkgs.emptyFile;
        };
        btrfs-scrub = {
          enable = true;
          filesystems = ["/"];
        };
        cloudflared = {
          certificateFile = toString pkgs.emptyFile;
        };
        ddclient = {
          configOptions = "";
          enable = true;
          passwordFile = toString pkgs.emptyFile;
        };
        flatpak.enable = true;
        forgejo-runner = {
          enable = true;
          enableGenericHostLabels = true;
          enableGenericLabels = true;
          enablePerSystemBuildLabels = true;
          enablePrivilegedLabels = true;
          enableSpesificHostLabels = true;
          forgejoRunnerTokenPath = toString pkgs.emptyFile;
          runnerImageRoot = "docker.tgdev.net/public/mirror/catthehacker/ubuntu";
          url = "http://127.0.0.1";
        };
        locate = {
          enable = true;
          interval = "hourly";
        };
        openssh.enable = true;
        pipewire.enable = true;
        printing = {enable = isX86;};
        renovate = {
          enable = true;
          endpoint = "http://127.0.0.1";
          extraKnownSSHKeys = {};
          githubTokenPath = toString pkgs.emptyFile;
          platform = "forgejo";
          sshKeyPath = toString pkgs.emptyFile;
          tokenPath = toString pkgs.emptyFile;
        };
        smartd.enable = true;
        sunshine = {
          enable = true;
          enableCUDA = isX86;
        };
        syncthing.enable = true;
        tailscale.enable = true;
        thinkfan.enable = true;
        tlp.enable = true;
        zot = {
          caddy = {
            domain = "docker.tgdev.net";
            domainAliases = ["docker.tgdev.ca"];
            extraConfig = ''
              import base_config
              request_body {
                max_size 0
              }
              reverse_proxy host.docker.internal:${config.services.zot.settings.http.port} {
                flush_interval -1
                header_up Host {http.request.host}
                transport http {
                  dial_timeout 5s
                }
              }
            '';
            internalAddress = "host.docker.internal";
          };
          enable = true;
          htpasswdPath = toString pkgs.emptyFile;
          httpAccessControl = {};
        };
      };
      system-tweaks.enable = true;
      virtualisation = {
        containers = {
          caddy = {
            enable = true;
            subsites = {
              webfinger.enable = true;
            };
          };
          enableDefaultContainers = true;
          matrix-backend-call-support = {
            config = {
              coturnPath = toString pkgs.emptyFile;
              livekitJWTEnvPath = toString pkgs.emptyFile;
              livekitPath = toString pkgs.emptyFile;
            };
            enable = true;
          };
          plex.enable = true;
          vlmcsd.enable = true;
          watchtower.enable = true;
        };
        docker = {
          enable = true;
          nvidia = {enable = isX86;};
          storageDriver = "btrfs";
        };
        libvirt.enable = true;
      };
    };

    # Things to make the evaluator happy
    system.stateVersion = "24.11";
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
