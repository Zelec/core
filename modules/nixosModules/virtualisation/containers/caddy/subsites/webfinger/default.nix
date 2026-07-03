{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.virtualisation-containers-caddy-subsites-webfinger];
  };
  flake.nixosModules.virtualisation-containers-caddy-subsites-webfinger = {
    config,
    lib,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.virtualisation.containers.caddy.subsites.webfinger;
  in {
    options.zelec-core.virtualisation.containers.caddy.subsites.webfinger = {
      enable = lib.mkEnableOption "Enables webfinger subsite";
    };
    config = lib.mkIf cfg.enable {
      zelec-core.virtualisation.containers.caddy.virtualHosts = {
        "webfinger.timeguard.ca" = {
          extraConfig = ''
            @webfinger {
              path /.well-known/webfinger
              method GET HEAD
              query resource=acct:isaac@timeguard.ca resource=mailto:isaac@timeguard.ca resource=acct:zelec@timeguard.ca resource=mailto:zelec@timeguard.ca resource=https://timeguard.ca resource=https://timeguard.ca/ resource=https://webfinger.timeguard.ca resource=https://webfinger.timeguard.ca/
            }
            route @webfinger {
              header Content-Type "application/jrd+json"
              header Access-Control-Allow-Origin "*"
              header X-Robots-Tag "noindex"
              templates {
                mime application/jrd+json
              }
              respond `{"subject": "{{.Req.URL.Query.Get "resource"}}", "links": [{"rel": "http://openid.net/specs/connect/1.0/issuer", "href": "https://keycloak.timeguard.ca/realms/TimeGuard"}]}` 200
              file_server
            }
            header X-Robots-Tag "noindex"
            redir / https://blog.timeguard.ca temporary
          '';
        };
      };
    };
  };
}
