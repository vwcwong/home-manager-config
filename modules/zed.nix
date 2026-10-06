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
  #
  # The driver needs other host libraries too, but the host's glibc is older
  # than Nix's and must not shadow it, so link everything except glibc into a
  # runtime directory. The build sandbox can't see /usr/lib, so this happens
  # at launch.
  linkHostLibs = ''
    hostLibDir="''${XDG_RUNTIME_DIR:-/tmp}/zed-host-libs"
    mkdir -p "$hostLibDir"
    hostLibs=()
    for lib in /usr/lib/x86_64-linux-gnu/*.so*; do
      case "''${lib##*/}" in
        ld-linux*|libc.so*|libm.so*|libmvec.so*|libdl.so*|libpthread.so*|librt.so*|libresolv.so*|libutil.so*|libanl.so*|libnsl.so*|libBrokenLocale.so*|libnss_*|libthread_db.so*|libc_malloc_debug.so*|libmemusage.so|libpcprofile.so) ;;
        *) hostLibs+=("$lib") ;;
      esac
    done
    ln -sf "''${hostLibs[@]}" "$hostLibDir"/
    export LD_LIBRARY_PATH="$hostLibDir''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  zed-editor-nvidia = pkgs.symlinkJoin {
    name = "zed-editor-nvidia";
    paths = [ pkgs.zed-editor ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zeditor \
        --set VK_ICD_FILENAMES /usr/share/vulkan/icd.d/nvidia_icd.json \
        --run ${lib.escapeShellArg linkHostLibs}
    '';
  };
in
{
  programs.zed-editor = {
    enable = true;
    package = lib.mkIf isLinux zed-editor-nvidia;
    extensions = [ "dockerfile" "java" "nix" "python" ];
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
