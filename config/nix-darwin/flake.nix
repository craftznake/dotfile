{
  description = "My macOS system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-registry = {
      url = "github:nixos/flake-registry";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, darwin, ... }:
    let
      supportedSystems = [ "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Resolved from the shell invoking `nix build`/`darwin-rebuild`
      # (see `makefile`), so this flake works on whatever machine it's
      # run on without hardcoding a specific host.
      username = builtins.getEnv "USER";
      hostname = builtins.getEnv "HOST";
      uidStr = builtins.getEnv "UID";

      assertNonEmpty =
        name: value:
        if value == "" then
          throw "${name} is empty; run via `make` (which exports it) or export ${name} yourself, and pass --impure"
        else
          value;
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      darwinConfigurations."${assertNonEmpty "HOST" hostname}" = darwin.lib.darwinSystem {
        system = builtins.currentSystem;
        specialArgs = {
          username = assertNonEmpty "USER" username;
          uid = builtins.fromJSON (assertNonEmpty "UID" uidStr);
          inherit hostname;
        };
        modules = [
          ./modules/darwin/index.nix
        ];
      };
    };
}
