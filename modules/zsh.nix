{ pkgs, lib, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      hm-switch = "home-manager switch --impure";
      hm-pull = "git -C ~/.config/home-manager fetch && (git -C ~/.config/home-manager merge --ff-only @{u} || git -C ~/.config/home-manager reset --hard @{u})";
      zed = if isLinux then "nixGL zeditor" else "zeditor";
    };
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "p10k-config";
        src = lib.cleanSource ../zsh;
        file = "p10k.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];
    initExtra = ''
      #
      # Bind Ctrl+Left/Right for word navigation
      #

      # Linux terminals (xterm-style, rxvt-style, vt100-style)
      bindkey "\e[1;5D" backward-word
      bindkey "\e[5D" backward-word
      bindkey "\eOD" backward-word
      bindkey "^[[1;5D" backward-word

      bindkey "\e[1;5C" forward-word
      bindkey "\e[5C" forward-word
      bindkey "\eOC" forward-word
      bindkey "^[[1;5C" forward-word

      # Mac terminals - Option+Arrow is standard for word navigation on Mac
      bindkey "\e[1;3D" backward-word    # Option+Left
      bindkey "\e[1;3C" forward-word     # Option+Right
      bindkey "\e\e[D" backward-word    # Alternative Option+Left format
      bindkey "\e\e[C" forward-word     # Alternative Option+Right format

      # Mac terminals - Ctrl+Arrow (iTerm2, Terminal.app may need special config)
      bindkey "^[^[[D" backward-word    # Ctrl+Left (some Mac terminals)
      bindkey "^[^[[C" forward-word     # Ctrl+Right (some Mac terminals)

      # Also bind ESC+b and ESC+f for compatibility (standard readline)
      bindkey "\eb" backward-word
      bindkey "\ef" forward-word
    '';
  };
}
