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
      {
        name = "FelixKratz/formulae";
        trusted = true;
      }
      {
        name = "sozercan/repo";
        trusted = true;
      }
      {
        name = "nikitabobko/tap";
        trusted = true;
      }
      {
        name = "atlassian/homebrew-acli";
        trusted = true;
      }
      {
        name = "wxtsky/tap";
        trusted = true;
      }
    ];

    # `brew install`
    brews = [
      "acli"
      "create-dmg"
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
      "terminal-notifier"
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
      "firefox"
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
