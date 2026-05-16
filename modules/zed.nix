{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [ "java" "nix" "python" ];
    userSettings = {
      ui_font_size = 12;
      ui_font_family = "MesloLGS NF";
      buffer_font_size = 11;
      buffer_font_family = "MesloLGS NF";
      cli_default_open_behavior = "existing_window";
      terminal = {
        dock = "right";
      };
      lsp = {
        jdtls = {
          binary = {
            path = "${pkgs.jdt-language-server}/bin/jdtls";
          };
        };
        nixd = {
          binary = {
            path = "${pkgs.nixd}/bin/nixd";
          };
        };
        pyright = {
          binary = {
            path = "${pkgs.pyright}/bin/pyright-langserver";
            arguments = [ "--stdio" ];
          };
        };
      };
    };
  };
}
