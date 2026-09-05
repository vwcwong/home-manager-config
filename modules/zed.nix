{ pkgs, lib, config, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  hostNvidiaLibDir = "/usr/lib/x86_64-linux-gnu";

  # Symlink farm containing only the NVIDIA-specific driver libraries (built
  # by home.activation below, since it needs to read the host's
  # /usr/lib/x86_64-linux-gnu at switch time, which the Nix build sandbox
  # can't see). Deliberately excludes generic host libs (libc, libX11, etc.)
  # so this directory can be safely added to LD_LIBRARY_PATH without
  # shadowing Nix's own copies of those libs in other processes.
  nvidiaLibDir = "${config.home.homeDirectory}/.local/state/zed-nvidia-libs";

  # The nix-packaged zed-editor is normally launched through nixGL, but
  # nixGL's NVIDIA auto-detection can't read /proc/driver/nvidia/version
  # inside the Nix build sandbox and silently falls back to nixGLMesa. Mesa
  # only exposes the AMD Radeon iGPU here, which has no display output, so
  # Vulkan surface creation fails ("not compatible with the display surface
  # for this window"). The RTX 5080 is the only GPU actually wired to a
  # display.
  #
  # Bypass nixGL for Zed entirely and point it straight at the host's own
  # NVIDIA Vulkan driver and ICD instead. LD_LIBRARY_PATH is scoped to
  # nvidiaLibDir (not the whole host lib dir) because it's exported into
  # Zed's process environment and inherited by every subprocess Zed spawns
  # (e.g. git) — pointing it at the full host lib dir previously shadowed
  # Nix's own libpcre2 for git with the host's incompatible version.
  zed-editor-nvidia = pkgs.symlinkJoin {
    name = "zed-editor-nvidia";
    paths = [ pkgs.zed-editor ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zeditor \
        --set VK_ICD_FILENAMES /usr/share/vulkan/icd.d/nvidia_icd.json \
        --prefix LD_LIBRARY_PATH : "${nvidiaLibDir}"
    '';
  };
in
{
  home.activation.zedNvidiaLibs = lib.mkIf isLinux (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${nvidiaLibDir}"
      run find "${nvidiaLibDir}" -maxdepth 1 -type l -delete
      for lib in "${hostNvidiaLibDir}"/libnvidia-*.so* "${hostNvidiaLibDir}"/libGLX_nvidia.so*; do
        [ -e "$lib" ] && run ln -sf "$lib" "${nvidiaLibDir}/$(basename "$lib")"
      done
    ''
  );

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
