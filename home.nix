{ config, pkgs, lib, username, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  unsupported = builtins.abort "Unsupported platform";
in
{
  imports = [
    ./modules/direnv.nix
    ./modules/git.nix
    ./modules/tmux.nix
    ./modules/zed.nix
    ./modules/zsh.nix
  ];

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
    opencode

  ] ++ lib.optionals isLinux [
    # Linux-only dependencies
    pkgs.nixgl.auto.nixGLDefault
  ] ++ lib.optionals isDarwin [
    # Mac-only dependencies
  ]);
}
