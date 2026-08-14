{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    mkalias
  ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };

    taps = [
      "nikitabobko/tap"
      "FelixKratz/formulae"
      "sozercan/repo"
      "atlassian/homebrew-acli"
      "wxtsky/tap"
    ];

    # `brew install`
    brews = [
      "acli"
      "antidote"
      "aspell"
      "autoconf"
      "clang-format"
      "cmake"
      "coreutils"
      "displayplacer"
      "docker-buildx"
      "git-crypt"
      "libtool"
      "ninja"
      "slides"
      "tlrc"
      "watch"
    ];

    # `brew install --cask`
    casks = [
      "aerospace"
      "alacritty"
      "aldente"
      "codeisland"
      "codex"
      "cursor"
      "finicky"
      "ghostty"
      "homerow"
      "jordanbaird-ice"
      "karabiner-elements"
      "kaset"
      "middleclick"
      "obsidian"
      "openkey"
      "raycast"
      "stats"
      "wezterm"
      "zed"
      "zen"
    ];
  };
  programs.zsh.enable = true;
}
