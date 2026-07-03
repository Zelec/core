{
  description = "Zelec's Nix Core";

  inputs = {
    # Baseline flake boilerplate
    # Nixpkgs base
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # Flake Parts for dendritic patterning
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Import Tree to simplify nix file loading
    import-tree.url = "github:denful/import-tree";

    # Attic, Nix Binary Cache server
    attic.url = "github:zhaofengli/attic";
    attic.inputs.nixpkgs.follows = "nixpkgs";
    # Copyparty, portable file server
    copyparty.url = "github:9001/copyparty";
    copyparty.inputs.nixpkgs.follows = "nixpkgs";
    # Home Manager, Dotfile manager
    home-manager.url = "github:nix-community/home-manager?ref=release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Nix-Flatpak, Flatpak management via Nix
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    # Nix-Index-Database, Search for files in nixpkgs, and wrapper for comma
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    # Nix-VSCode-Extensions, used to manage VSCode/VSCodium extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
    # Nix User Repo, Used by Firefox managed addons
    nur.url = "github:nix-community/NUR";
    # NVIDIA Patch to auto patch NVENC and FBC
    nvidia-patch.url = "github:icewind1991/nvidia-patch-nixos";
    # Plasma Manager for managing KDE 6 settings
    plasma-manager.url = "github:nix-community/plasma-manager/trunk";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Stylix, Unified
    stylix.url = "github:danth/stylix?ref=release-26.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
  };
  # Main entrypoint, uses import-tree to load all nix files under ./modules
  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
