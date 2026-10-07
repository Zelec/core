# Default overlay set for use internally & externally if needed
{
  inputs,
  ...
}: {
  flake.overlays.default = final: prev: let
    composed = inputs.nixpkgs.lib.composeManyExtensions [
      inputs.copyparty.overlays.default
      inputs.nix-vscode-extensions.overlays.default
      inputs.nur.overlays.default
      inputs.nvidia-patch.overlays.default
    ];
  in
    composed final prev;
}
