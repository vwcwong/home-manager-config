{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;

    # LazyVim's external requirements
    extraPackages = with pkgs; [
      gcc
      tree-sitter
      fzf
      ripgrep
      fd
      lazygit
    ];

    # lazy.nvim manages plugins at runtime, outside the Nix store
    initLua = builtins.readFile ./neovim/init.lua;
  };

  xdg.configFile."nvim/lua".source = ./neovim/lua;
}
