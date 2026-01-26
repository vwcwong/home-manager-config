{ config, pkgs, lib, username, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  unsupported = builtins.abort "Unsupported platform";
in
{
  home.username = username;
  home.homeDirectory =
    if isLinux then "/home/${username}" else
    if isDarwin then "/Users/${username}" else unsupported;

  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; ([
    #
    # Platform-agnostic dependencies
    #

    # Fonts and icons
    meslo-lgs-nf

    # Docker - requires manual Docker Desktop installation on Mac
    docker
    docker-compose

    # Kubernetes tools
    kubectl
    kubernetes-helm
    k3d
    eksctl
    skaffold
    kustomize

    # AWS CLI
    awscli2

    # Rust tools
    rustc
    cargo
    rust-analyzer
    rustfmt

    # Terraform
    terraform

    # AI tools
    claude-code
  ] ++ lib.optionals isLinux [
    # Linux-only dependencies
  ] ++ lib.optionals isDarwin [
    # Mac-only dependencies
  ]);

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      hm-switch = "home-manager switch";
    };
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "p10k-config";
        src = lib.cleanSource ./zsh; 
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

  # Git configuration
  programs.git = {
    enable = true;
    userEmail = "vincent@vwong.dev";
    userName = "Vincent Wong";
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };
}