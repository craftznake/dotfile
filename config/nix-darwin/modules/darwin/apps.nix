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
    ];

    # `brew install`
    brews = [
      "antidote"
      "aspell"
      "autoconf"
      "clang-format"
      "cmake"
      "coreutils"
      "displayplacer"
      "docker-buildx"
        "acli"
      "firefoxpwa"
      "gemini-cli"
      "git-crypt"
      "libtool"
      "ninja"
      "slides"
      "tlrc"
      "watch"
    ];

    # `brew install --cask`
    casks = [
      "codex"
      "aerospace"
      "alacritty"
      "aldente"
      "openkey"
      "firefox"
      "homerow"
      "jordanbaird-ice"
      "karabiner-elements"
      "middleclick"
      "obsidian"
      "raycast"
      "stats"
      "cursor"
      "wezterm"
      "zed"
      "zen"
      "finicky"
      "ghostty"
      "kaset"
    ];
  };
  programs.zsh.enable = true;
}
