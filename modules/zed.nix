{ pkgs, lib, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # The nix-packaged zed-editor is normally launched through nixGL, but
  # nixGL's NVIDIA auto-detection can't read /proc/driver/nvidia/version
  # inside the Nix build sandbox and silently falls back to nixGLMesa. Mesa
  # only exposes the AMD Radeon iGPU here, which has no display output, so
  # Vulkan surface creation fails ("not compatible with the display surface
  # for this window"). The RTX 5080 is the only GPU actually wired to a
  # display.
  #
  # Bypass nixGL for Zed entirely and point it straight at the host's own
  # NVIDIA Vulkan driver and ICD instead.
  zed-editor-nvidia = pkgs.symlinkJoin {
    name = "zed-editor-nvidia";
    paths = [ pkgs.zed-editor ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zeditor \
        --set VK_ICD_FILENAMES /usr/share/vulkan/icd.d/nvidia_icd.json \
        --prefix LD_LIBRARY_PATH : /usr/lib/x86_64-linux-gnu
    '';
  };
in
{
  programs.zed-editor = {
    enable = true;
    package = lib.mkIf isLinux zed-editor-nvidia;
    extensions = [ "java" "nix" "python" ];
    userSettings = {
      disable_ai = true;
      ui_font_size = 12;
      ui_font_family = "MesloLGS NF";
      buffer_font_size = 11;
      buffer_font_family = "MesloLGS NF";
      cli_default_open_behavior = "existing_window";
      terminal = {
        dock = "right";
      };
      project_panel = {
        dock = "left";
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
