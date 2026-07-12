{
  description = "My home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jj-starship-overlay = {
        url = "github:dmmulroy/jj-starship";
    };
    herdr = {
        url = "github:ogulcancelik/herdr";
    };
    flake-registry = {
      url = "github:nixos/flake-registry";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, rust-overlay, jj-starship-overlay, herdr, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      
      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [
          rust-overlay.overlays.default
          jj-starship-overlay.overlays.default
          herdr.overlays.default
          (import ./overlays)
        ];
      };
      
      # For home-manager configuration
      system = builtins.currentSystem or "aarch64-darwin";
      username = builtins.getEnv "USER";
      homeDirectory = builtins.getEnv "HOME";
      pkgs = pkgsFor system;
    in
    {
      homeConfigurations = {
        "default" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./modules/home/index.nix
          ];
          extraSpecialArgs = {
            inherit username homeDirectory;
          };
        };
      };

      packages = forAllSystems (system: {
        inherit (pkgsFor system) tpack;
      });

      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixpkgs-fmt;
    };
}
