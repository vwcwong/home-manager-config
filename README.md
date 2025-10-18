# Home Manager Configuration
This repository contains my [Home Manager](https://nixos.wiki/wiki/Home_Manager) configuration for creating a reproducible, reliable, and cross-platform development environment.

To use this configuration, just follow these steps:
1. Install Nix via the [official installer](https://nixos.org/download/).
2. Clone this repository using `git clone https://github.com/V-Wong/home-manager-config.git ~/.config/home-manager`.
3. Fill in the placeholder values (`<FILL_IN>`) in [flake.nix](./flake.nix).
4. Start Home Manager with `nix run home-manager switch`.
5. Restart your terminal.