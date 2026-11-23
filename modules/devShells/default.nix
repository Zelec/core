{
  inputs,
  self,
  ...
}: {
  imports = [
    inputs.git-hooks.flakeModule
  ];
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    pre-commit.settings = {
      src = ./.;
      hooks = {
        alejandra.enable = true;
        deadnix.enable = true;
        statix.enable = true;
      };
    };
    devShells.default = pkgs.mkShell {
      inputsFrom = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.caddy-docker-proxy
        self.packages.${pkgs.stdenv.hostPlatform.system}.btrbk-mass-backup
      ];
      packages = with pkgs; [
        # General Development items
        git
        pre-commit
        sops

        # Go related items, helps with Caddy
        gopls
        golangci-lint

        # Nix build, inspection, and linting tools
        alejandra
        deadnix
        nh
        nix-output-monitor
        nixd
        nvd
        omnix
        statix
      ];
      shellHook = let
        nixpkgRev =
          if inputs.nixpkgs ? rev
          then builtins.substring 0 7 inputs.nixpkgs.rev
          else "dirty";
      in ''
        ${config.pre-commit.installationScript}
        echo "Zelec-Core devshell loaded"
        echo "NixPkgs revision date: $(date -d @${toString inputs.nixpkgs.lastModified} '+%Y-%m-%d %H:%M:%S %Z')"
        echo "NixPkgs commit sha: ${nixpkgRev}"
        echo "Using Go binary from: $(which go)"
        echo "Using Nix helper (nh): $(which nh)"
        echo "Using Nix version diff (nvd): $(which nvd)"
      '';
    };
  };
}
