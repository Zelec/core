{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-common-gui];
  };
  flake.nixosModules.programs-common-gui = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.common-gui;
  in {
    options.zelec-core.programs.common-gui = {
      enable = lib.mkEnableOption "Enables common gui packages";
    };
    config = lib.mkIf cfg.enable {
      zelec-core.programs = {
        chromium.enable = true;
        discord.enable = true;
        firefox.enable = true;
        hunspell.enable = true;
        obs.enable = true;
        vscodium.enable = true;
      };
      environment.systemPackages = with pkgs;
        [
          brightnessctl
          cinny-desktop
          crosspipe
          deluge-gtk
          element-desktop
          gimp
          gocryptfs
          gparted-full
          krita
          libreoffice-qt-fresh
          moonlight-qt
          papirus-icon-theme
          pavucontrol
          rclone
          remmina
          source-code-pro
          tela-icon-theme
          thunderbird
          vlc
          vulkan-loader
          vulkan-tools
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
          finamp
          prismlauncher
          proton-vpn
          teamspeak6-client
          uhk-agent
          uhk-udev-rules
          zoom-us
          pkgs.unstable.ventoy-full-qt
        ];
      # Enable appimage use on NixOS
      programs.appimage.binfmt = true;
    };
  };
}
