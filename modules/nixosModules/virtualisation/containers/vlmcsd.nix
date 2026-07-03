# Very legacy, fun to convert into a nix package and make work inside of a nix centric container
# But I don't run windows personally anymore in any capacity, and having this open to the internet is just asking for abuse
{
  self,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages = {
      vlmcsd = pkgs.stdenv.mkDerivation rec {
        pname = "vlmcsd";
        version = "1113";
        src = pkgs.fetchFromGitHub {
          owner = "Wind4";
          repo = "vlmcsd";
          rev = "svn${version}";
          sha256 = "sha256-OKysOm44T9wrAaopp9HfLlox5InlpV33AHGXRSjhDqc=";
        };
        nativeBuildInputs = [pkgs.gnumake pkgs.gcc];
        makeFlags = ["CLIENT_STATIC=1" "SERVER_STATIC=1"];
        buildPhase = ''
          make
        '';
        installPhase = ''
          # Programs
          mkdir -p $out/bin
          cp bin/vlmcsd $out/bin/
          cp bin/vlmcs $out/bin/
          # Support Files
          mkdir -p $out/share/vlmcsd
          cp etc/vlmcsd.kmd $out/share/vlmcsd/
          mkdir -p $out/share/man/man{1,5,7,8}
          cp man/*.1 $out/share/man/man1/
          cp man/*.5 $out/share/man/man5/
          cp man/*.7 $out/share/man/man7/
          cp man/*.8 $out/share/man/man8/
          # Space optimizer
          ${pkgs.stdenv.cc.targetPrefix}strip $out/bin/vlmcsd
          ${pkgs.stdenv.cc.targetPrefix}strip $out/bin/vlmcs
        '';
        meta = with pkgs.lib; {
          description = "KMS Emulator in C";
          homepage = "https://github.com/Wind4/vlmcsd";
          license = licenses.mit;
          platforms = platforms.unix;
        };
      };
      vlmcsd-oci-image = pkgs.dockerTools.buildLayeredImage {
        name = "docker.tgdev.net/zelec/vlmcsd-tg-nix";
        tag = "latest";
        contents = [
          self.packages.${pkgs.stdenv.hostPlatform.system}.vlmcsd
          pkgs.tzdata
        ];
        config = {
          Cmd = [
            "${self.packages.${pkgs.stdenv.hostPlatform.system}.vlmcsd}/bin/vlmcsd"
            # Run in Foreground
            "-D"
            # Disconnect clients after each request
            "-d"
            # Disconnect clients after a timeout in seconds
            "-t"
            # In this case 3 seconds
            "3"
            # Log output to stdout
            "-e"
            # Verbose
            "-v"
            # Sets KMS file
            "-j"
            # KMS File path
            "${self.packages.${pkgs.stdenv.hostPlatform.system}.vlmcsd}/share/vlmcsd/vlmcsd.kmd"
          ];
          ExposedPorts = {
            "1688/tcp" = {};
          };
        };
      };
    };
  };
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-containers-vlmcsd];
  };
  flake.nixosModules.virtualisation-containers-vlmcsd = {
    config,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.containers.vlmcsd;
  in {
    options.zelec-core.virtualisation.containers.vlmcsd = {
      enable = lib.mkEnableOption "Enables vlmcsd container stack";
    };

    config = lib.mkIf cfg.enable {
      zelec-core.virtualisation.dockerManager.vlmcsd = {
        containerNames = [
          "vlmcsd"
        ];
      };
      networking.firewall = {
        allowedTCPPorts = [
          1688
        ];
      };
      virtualisation.oci-containers.containers."vlmcsd" = {
        imageFile = self.packages.${pkgs.stdenv.hostPlatform.system}.vlmcsd-oci-image;
        image = "docker.tgdev.net/zelec/vlmcsd-tg-nix:latest";
        pull = "never";
        ports = [
          "1688:1688"
        ];
        log-driver = "journald";
      };
    };
  };
}
