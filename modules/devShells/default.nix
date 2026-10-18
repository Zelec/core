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
      shellHook = ''
        ${config.pre-commit.installationScript}
        echo "Devshell loaded from nixpkgs revision: ${inputs.nixpkgs.rev or "dirty"}"
        echo "Using Go binary from: $(which go)"
        echo "Using Nix helper (nh): $(which nh)"
      '';
    };
  };
}
