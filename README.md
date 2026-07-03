# Zelec's Nix Core

A cobbling of my opinionated NixOS settings for my personal systems

Quite a bit of this was based on [IronicBadger's Nix Config Repo](https://github.com/ironicbadger/nix-config), [Vimjoyer's excellent videos](https://www.youtube.com/@vimjoyer), scrappings I've pulled together from the internet, and/or AI when I am just lost on how to make something work in Nix.

This was made so I can keep my primary system configs private, but I wanted to still share most of what I figure out and use

If you do want to use this, I won't stop you but I likely won't help you either. Regardless my recommended way to use these modules is to import the `zelec-core.nixosModules.default` module into your flake's nixosConfiguration

Example:
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    # Or if you want your nixpkgs to follow my framework, you can do something like this
    # nixpkgs.follows = "zelec-core/nixpkgs";
    zelec-core.url = "github:zelec/core";
  };
  outputs = { inputs, ... }: {
    nixosConfigurations."«hostname»" = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        inputs.zelec-core.nixosModules.default
        ./configuration.nix
        ./hardware-configuration.nix
        { 
          nixpkgs.hostPlatform = "x86_64-linux";
          # Use nix repl to find out the configurable options, or check out the included test
          # host config under ./modules/nixosConfigurations/Test
          zelec-core = {
            autoEnable = true;
            programs = {
              adb.enable = true;
              firefox.enable = true;
              wine.enable = true;
            };
            services = {
              flatpak.enable = true;
              syncthing.enable = true;
              tailscale.enable = true;
            };
          };
        }
      ];
    };
  };
}
```

All nix files also output their own individual modules (for example if you just wanted to load up some of my services or some things) you can, however some of these modules are dependant on the base module being loaded and existing.

Again you do what you want, but please don't open up issues asking me for help.
