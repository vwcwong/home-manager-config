{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [ "java" ];
    userSettings = {
      ui_font_size = 12;
      ui_font_family = "MesloLGS NF";
      buffer_font_size = 11;
      buffer_font_family = "MesloLGS NF";
      lsp = {
        jdtls = {
          binary = {
            path = "${pkgs.jdt-language-server}/bin/jdtls";
          };
        };
      };
    };
  };
}
