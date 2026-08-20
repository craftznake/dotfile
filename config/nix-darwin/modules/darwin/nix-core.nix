{ pkgs, ... }:
{
  nix = {
    enable = false;
    #package = pkgs.nix;
    #optimise = {
    #  automatic = true;
    #};

    ## Enable flakes globally
    #settings = {
    #  experimental-features = [ "nix-command" "flakes" ];
    #  trusted-users = [ "root" "@admin" ];
    #  allowed-users = [ "@admin" ];
    #};

    ## Configure binary caches for faster builds
    #settings.substituters = [
    #  "https://cache.nixos.org"
    #  "https://nix-community.cachix.org"
    #];
    #settings.trusted-public-keys = [
    #  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    #  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    #];

    ## Configure garbage collection
    #gc = {
    #  automatic = true;
    #  interval = { Weekday = 0; Hour = 0; Minute = 0; };
    #  options = "--delete-older-than 30d";
    #};

    ## Configure nix path
    #nixPath = [
    #  "nixpkgs=${pkgs.path}"
    #  "darwin=/run/current-system/darwin"
    #  "darwin-config=/etc/nixpkgs/darwin-configuration.nix"
    #];
  };
}
