{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-common-cli];
  };
  flake.nixosModules.programs-common-cli = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.common-cli;
  in {
    options.zelec-core.programs.common-cli = {
      enable = lib.mkEnableOption "Enables common cli packages";
    };
    config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs;
        [
          alejandra
          ansible
          attic-client
          bash
          bitwarden-cli
          borgbackup
          borgmatic
          btdu
          btop
          cdrtools
          copyparty
          coreutils
          cryptsetup
          curl
          deadnix
          devbox
          devenv
          dig
          distrobox
          e2fsprogs
          ffmpeg
          git
          gnumake
          go
          gocryptfs
          gptfdisk
          htop
          jq
          just
          lm_sensors
          magic-wormhole
          minicom
          mosh
          nano
          ncdu
          nh
          nix-eval-jobs
          nix-fast-build
          nix-output-monitor
          nixd
          nixos-install-tools
          ntfs3g
          nvd
          omnix
          pciutils
          polkit
          pulseaudio
          pv
          screen
          smartmontools
          sops
          statix
          terraform
          tmux
          unzip
          usbutils
          vim
          watch
          wget
          wireguard-tools
          zstd

          (python3.withPackages (
            ps: [
              ps.ansible
              ps.pip
              ps.requests
              ps.tkinter
            ]
          ))

          pkgs.unstable.yt-dlp
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
          glances
        ];
    };
  };
}
