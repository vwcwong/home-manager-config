{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [ "java" ];
    userSettings = {
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
