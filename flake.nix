{
  description = "github.com/V-Wong/home-manager-config";

  inputs.nixpkgs = {
    url = "github:nixos/nixpkgs/nixpkgs-unstable";  ## Bleeding edge packages
  };

  inputs.home-manager = {
    url = "github:nix-community/home-manager/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }: 
  let
    username = <FILL_IN>;
    isDarwin = <FILL_IN>;
    
    linuxConfig = {
      "${username}" = home-manager.lib.homeManagerConfiguration ({
        modules = [ ./home.nix ];
        extraSpecialArgs = { username = username; };
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
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
        };
      });
    };
  in {
    homeConfigurations = if isDarwin then macConfig else linuxConfig;
  };
}