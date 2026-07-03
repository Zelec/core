{self, ...}: {
  flake.nixosModules.default = {
    imports = [self.nixosModules.programs-neovim];
  };
  flake.nixosModules.programs-neovim = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfgRoot = config.zelec-core;
    cfg = cfgRoot.programs.neovim;
  in {
    options.zelec-core.programs.neovim = {
      enable = lib.mkEnableOption "Enables neovim";
    };
    config = lib.mkIf cfg.enable {
      users.users.${config.zelec-core.base.user.name}.packages = with pkgs; [
        fd
        ripgrep
      ];
      home-manager.users.${config.zelec-core.base.user.name} = {
        programs.neovim = {
          enable = true;
          defaultEditor = false;
          viAlias = true;
          vimAlias = true;
          withRuby = true;
          withPython3 = true;
          plugins = with pkgs.vimPlugins; [
            neo-tree-nvim
            telescope-nvim
            nvim-web-devicons
            nvim-treesitter
          ];
          extraConfig = ''
            set shiftwidth=2 smarttab
            set expandtab
            set tabstop=8 softtabstop=0
          '';
          initLua = ''

            require("telescope").setup()
          '';
        };
      };
    };
  };
}
