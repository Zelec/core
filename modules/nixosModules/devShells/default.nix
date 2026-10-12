{
  inputs,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      inputsFrom = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.caddy-docker-proxy
        self.packages.${pkgs.stdenv.hostPlatform.system}.btrbk-mass-backup
      ];
      packages = with pkgs; [
        # Go related items
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

        # Secret management
        sops
      ];
      shellHook = ''
        echo "Devshell loaded from nixpkgs revision: ${inputs.nixpkgs.rev or "dirty"}"
        echo "Using Go binary from: $(which go)"
        echo "Using Nix helper (nh): $(which nh)"
      '';
    };
  };
}
