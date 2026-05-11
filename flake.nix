{
  description = "github.com/V-Wong/home-manager-config";

  inputs.nixpkgs = {
    url = "github:nixos/nixpkgs/nixpkgs-unstable";  ## Bleeding edge packages
  };

  inputs.home-manager = {
    url = "github:nix-community/home-manager/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.claude-code = {
    url = "github:sadjow/claude-code-nix";
  };

  inputs.nixgl = {
    url = "github:nix-community/nixGL";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, claude-code, nixgl }:
  let
    username = builtins.getEnv "USER";
    isDarwin = builtins.pathExists /Library;
    
    linuxConfig = {
      "${username}" = home-manager.lib.homeManagerConfiguration ({
        modules = [ ./home.nix ];
        extraSpecialArgs = { username = username; };
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ claude-code.overlays.default nixgl.overlay ];
        };
      });
    };

    macConfig = {
      "${username}" = home-manager.lib.homeManagerConfiguration ({
        modules = [ ./home.nix ];
        extraSpecialArgs = { username = username; };
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
          overlays = [ claude-code.overlays.default ];
        };
      });
    };
  in {
    homeConfigurations = if isDarwin then macConfig else linuxConfig;
  };
}