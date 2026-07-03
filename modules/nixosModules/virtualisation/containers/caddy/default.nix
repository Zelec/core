# Caddy Container
# Autoenabled with config.zelec-core.virtualisation.containers.enableDefaultContainers = true;
# and thus via config.zelec-core.autoEnable = true;
{
  inputs,
  self,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: let
    # Output hash of the caddy src plus plugins below
    # last reason this changed: Upgrade to 26.05 coincidentally had Caddy 2.11.4
    caddyHash = "sha256-OYJ5lHiwNc1HMA01NaS3c8x86znSCgU7Np/SuPPQnKk=";
  in {
    packages = {
      caddy-docker-proxy = pkgs.caddy.withPlugins {
        plugins = [
          # https://github.com/caddy-dns/cloudflare/releases/tag/v0.2.4
          # https://github.com/caddy-dns/cloudflare/commit/a8737d095ad5a48ca031cea6ab704057dbc2d250
          "github.com/caddy-dns/cloudflare@v0.2.4"
          # No releases available for this plugin
          # https://github.com/mentimeter/caddy-storage-cf-kv/commit/939ac14649ca537a3cd7108e46cd57cfda593a91
          "github.com/mentimeter/caddy-storage-cf-kv@v0.0.0-20250219160011-939ac14649ca"
          # https://github.com/lucaslorentz/caddy-docker-proxy/releases/tag/v2.12.0
          # https://github.com/lucaslorentz/caddy-docker-proxy/commit/2eafc7ee742e77eacfc78f2c64095bc396eb3ea6
          "github.com/lucaslorentz/caddy-docker-proxy/v2@v2.12.0"
        ];
        hash = caddyHash;
      };
      caddy-oci-image = pkgs.dockerTools.buildLayeredImage {
        name = "docker.tgdev.net/zelec/caddy-tg-nix";
        tag = "nix-controlled";
        contents = [
          pkgs.cacert
          pkgs.coreutils-full
          pkgs.curl
          self.packages.${pkgs.stdenv.hostPlatform.system}.caddy-docker-proxy
        ];
        config = {
          Cmd = [
            "${self.packages.${pkgs.stdenv.hostPlatform.system}.caddy-docker-proxy}/bin/caddy"
            "docker-proxy"
            # "--ingress-networks"
            # "routable"
            # "--caddyfile-path"
            # "${caddyFile}"
          ];
          ExposedPorts = {
            "80/tcp" = {};
            "443/tcp" = {};
          };
          Env = [
            "XDG_CONFIG_HOME=/config"
            "XDG_DATA_HOME=/data"
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          ];
          Healthcheck = {
            # 30s
            Interval = 30000000000;
            Retries = 3;
            # 60s
            StartPeriod = 60000000000;
            Test = [
              "CMD"
              "curl"
              "--silent"
              "--fail"
              "--output"
              "/dev/null"
              "http://localhost:2019/config/"
            ];
            # 10s
            Timeout = 10000000000;
          };
        };
      };
    };
  };
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-containers-caddy];
  };
  flake.nixosModules.virtualisation-containers-caddy = {
    config,
    lib,
    pkgs,
    ...
  }: let
    # Fair warning, alot of code from NixPKGs was taken to make the VirtualHosts module work here
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.containers.caddy;
    virtualHosts = cfg.virtualHosts;
    mkVHostConf = hostOpts: ''
      ${hostOpts.hostName} ${lib.concatStringsSep " " hostOpts.serverAliases} {
        ${lib.optionalString (
        hostOpts.listenAddresses != []
      ) "bind ${lib.concatStringsSep " " hostOpts.listenAddresses}"}

        ${lib.optionalString (hostOpts.logFormat != null) ''
        log {
          ${hostOpts.logFormat}
        }
      ''}

        ${hostOpts.extraConfig}
      }
    '';
    configFile = let
      Caddyfile = pkgs.writeTextDir "Caddyfile" ''
        ${cfg.defaultCaddyFile}
        ${cfg.extraConfig}
        ${lib.concatMapStringsSep "\n" mkVHostConf (lib.attrValues virtualHosts)}
      '';
      Caddyfile-formatted = pkgs.runCommand "Caddyfile-formatted" {} ''
        mkdir -p $out
        cp --no-preserve=mode ${Caddyfile}/Caddyfile $out/Caddyfile
        ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.caddy-docker-proxy} fmt --overwrite $out/Caddyfile
      '';
    in "${
      if pkgs.stdenv.buildPlatform == pkgs.stdenv.hostPlatform
      then Caddyfile-formatted
      else Caddyfile
    }/Caddyfile";
    caddyFile = configFile;
  in {
    options.zelec-core.virtualisation.containers.caddy = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfgRoot.virtualisation.containers.enableDefaultContainers;
      };
      timeZone = lib.mkOption {
        type = lib.types.str;
        default = cfgRoot.base.timeZone;
      };
      envFilePath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      extraConfig = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      defaultCaddyFile = lib.mkOption {
        type = lib.types.str;
        default = ''
          {
            http_port 80
            https_port 443
          }
        '';
        example = ''
          {
            http_port 80
            https_port 443
            email zelec@timeguard.ca
            storage cloudflare_kv {
              account_id "{env.CF_ACCOUNT_API_ID}"
              api_token "{env.CF_ACCOUNT_API_TOKEN}"
              namespace_id "{env.CF_KV_NAMESPACE_ID}"
            }
            acme_dns cloudflare {env.CF_ACCOUNT_API_TOKEN}
          }
          (base_config) {
            tls {
              dns cloudflare {env.CF_ACCOUNT_API_TOKEN}
              resolvers 1.1.1.1 1.0.0.1
            }
            handle_errors {
              respond "{err.status_code} {err.status_text}"
            }
          }
          (basicauth) {
            basic_auth {
              Zelec {env.ZELEC_HTPASSWORD}
            }
          }
        '';
      };
      dockerNetworkName = lib.mkOption {
        type = lib.types.str;
        default = "routable";
      };
      appdataFolder = lib.mkOption {
        type = lib.types.str;
        default = "/opt/dockerservices/caddy";
      };
      dataFolder = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.appdataFolder}/data";
      };
      configFolder = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.appdataFolder}/config";
      };
      virtualHosts = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
          options = {
            hostName = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "Canonical hostname for the server.";
            };
            serverAliases = lib.mkOption {
              type = with lib.types; listOf str;
              default = [];
              example = [
                "www.example.org"
                "example.org"
              ];
              description = ''
                Additional names of virtual hosts served by this virtual host configuration.
              '';
            };
            listenAddresses = lib.mkOption {
              type = with lib.types; listOf str;
              description = ''
                A list of host interfaces to bind to for this virtual host.
              '';
              default = [];
              example = [
                "127.0.0.1"
                "::1"
              ];
            };
            # useACMEHost = lib.mkOption {
            #   type = lib.types.nullOr lib.types.str;
            #   default = null;
            #   description = ''
            #     A host of an existing Let's Encrypt certificate to use.
            #     This is mostly useful if you use DNS challenges but Caddy does not
            #     currently support your provider.

            #     *Note that this option does not create any certificates, nor
            #     does it add subdomains to existing ones – you will need to create them
            #     manually using [](#opt-security.acme.certs).*
            #   '';
            # };
            logFormat = lib.mkOption {
              type = lib.types.nullOr lib.types.lines;
              default = null;
              example = lib.literalExpression ''
                mkForce '''
                  output discard
                ''';
              '';
              description = ''
                Configuration for HTTP request logging (also known as access logs). See
                <https://caddyserver.com/docs/caddyfile/directives/log#log>
                for details.
              '';
            };
            extraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = ''
                Additional lines of configuration appended to this virtual host in the
                automatically generated `Caddyfile`.
              '';
            };
          };
        }));
        default = {};
        example = lib.literalExpression ''
          {
            "hydra.example.com" = {
              serverAliases = [ "www.hydra.example.com" ];
              extraConfig = '''
                encode gzip
                root * /srv/http
              ''';
            };
          };
        '';
        description = ''
          Declarative specification of virtual hosts served by Caddy.
        '';
      };
    };
    config = let
      files = ./files;
    in
      lib.mkIf cfg.enable {
        # Setup outside of the docker namespace so it exists outside the scope of any compose frameworks
        systemd.services."docker-network-${cfg.dockerNetworkName}" = {
          path = [pkgs.docker];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            #ExecStop = "${pkgs.docker}/bin/docker network rm -f ${cfg.dockerNetworkName}";
          };
          script = "docker network inspect ${cfg.dockerNetworkName} || docker network create ${cfg.dockerNetworkName}";
          partOf = ["docker-compose-webserver-root.target"];
          wantedBy = ["docker-compose-webserver-root.target"];
        };
        zelec-core.virtualisation.dockerManager.webserver = {
          containerNames = [
            "caddy"
          ];
        };
        virtualisation.oci-containers.containers."caddy" = {
          imageFile = self.packages.${pkgs.stdenv.hostPlatform.system}.caddy-oci-image;
          image = "docker.tgdev.net/zelec/caddy-tg-nix:nix-controlled";
          pull = "never";
          environment = {
            "TZ" = cfg.timeZone;
          };
          cmd = [
            "caddy"
            "docker-proxy"
            "--ingress-networks"
            "${cfg.dockerNetworkName}"
            "--caddyfile-path"
            "/etc/caddy/Caddyfile"
          ];
          ports = [
            "80:80"
            "443:443"
          ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock:ro"
            "${caddyFile}:/etc/caddy/Caddyfile:ro"
            "${cfg.configFolder}:/config"
            "${cfg.dataFolder}:/data"
            "${files}/errorPages:/errorPages:ro"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network-alias=caddy"
            "--network=${cfg.dockerNetworkName}"
            "--add-host=host.docker.internal:host-gateway"
          ];
          environmentFiles = [] ++ lib.optionals (cfg.envFilePath != null) cfg.envFilePath;
        };
      };
  };
}
