{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-sdr];
  };
  flake.nixosModules.programs-sdr = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.sdr;
  in {
    options.zelec-core.programs.sdr = {
      enable = lib.mkEnableOption "Enables Software Defined Radio";
    };
    config = lib.mkIf cfg.enable {
      hardware.rtl-sdr.enable = true;
      users.users.${config.zelec-core.base.user.name}.extraGroups = ["plugdev" "dialout"];
      environment.systemPackages = with pkgs; [
        chirp
        glfw
        gnuradio
        gqrx
        libusb1
        rtl-sdr
        sdrpp
        wayland-protocols
      ];
    };
  };
}
