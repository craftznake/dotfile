{ pkgs, username, config, ... }:
################################
#
# User dotfile
#
################################
let
  dotconfigs = "/Users/${username}/dotfile";
  antidoteFolder = "/Users/${username}/.antidote";
  antidote = pkgs.fetchFromGitHub {
    owner = "mattmc3";
    repo = "antidote";
    rev = "v1.9.10";
    hash = "sha256-+hp8L1Pcqx/Jly1H6F23U4WD6MkVAAZZpPrbc/VSurM=";
  };
in
{
  programs.zsh = {
    enable = true;
    sessionVariables = {
      EDITOR = "nvim";
      CLICOLOR = 1;
    };
    initContent = ''
      # FROM https://antidote.sh/
      source "${antidoteFolder}/antidote.zsh"

      source ~/.config/zsh/index.zsh
      if [[ $(uname -m) == 'arm64' ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
    '';
  };
  home.file = {
    "aerospace" = {
      source = "${dotconfigs}/config/aerospace";
      target = ".config/aerospace";
      recursive = true;
    };
    "eza" = {
      source = "${dotconfigs}/config/eza";
      target = ".config/eza";
      recursive = true;
    };
    "karabiner" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotconfigs}/config/karabiner/karabiner.json";
      target = ".config/karabiner/karabiner.json";
      force = true;
    };
    "nvim" = {
      source = "${dotconfigs}/config/nvim";
      target = ".config/nvim";
      recursive = true;
    };
    "wezterm" = {
      source = "${dotconfigs}/config/wezterm";
      target = ".config/wezterm";
      recursive = true;
    };
    "zsh" = {
      source = "${dotconfigs}/config/zsh";
      target = ".config/zsh";
      recursive = true;
    };
    "zsh_plugins" = {
      source = "${dotconfigs}/config/antidote-plugin.txt";
      target = ".zsh_plugins.txt";
      recursive = true;
    };
    "starship" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotconfigs}/config/starship.toml";
      target = ".config/starship.toml";
    };
    "scripts" = {
      source = "${dotconfigs}/scripts";
      target = ".scripts";
      recursive = true;
    };
    "antidote" = {
      source = antidote;
      target = antidoteFolder;
      recursive = true;
    };
    # NOTE: not used stuffs
    # "kitty" = {
    #   source = "${dotconfigs}/config/kitty";
    #   target = ".config/kitty";
    #   recursive = true;
    # };
    # "skhd" = {
    #   source = "${dotconfigs}/config/skhd";
    #   target = ".config/skhd";
    #   recursive = true;
    # };
    # "yabai" = {
    #   source = "${dotconfigs}/config/yabai";
    #   target = ".config/yabai";
    #   recursive = true;
    # };
    "tmux" = {
      source = "${dotconfigs}/config/tmux";
      target = ".config/tmux";
      recursive = true;
    };
    "herdr_config" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotconfigs}/config/herdr/config.toml";
        target = ".config/herdr/config.toml";
    };
    "herdr_plugins" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotconfigs}/config/herdr/plugins.txt";
        target = ".config/herdr/plugins.txt";
    };
    "alacritty" = {
      source = "${dotconfigs}/config/alacritty";
      target = ".config/alacritty";
      recursive = true;
    };
    # "fish" = {
    #   source = "${dotconfigs}/config/fish";
    #   target = ".config/fish";
    #   recursive = true;
    # };
  };

  home.activation = {
    installHerdrPlugins = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="$HOME/.nix-profile/bin:$PATH"

      if command -v herdr &> /dev/null; then
        plugins_file="$HOME/.config/herdr/plugins.txt"
        if [[ -f "$plugins_file" ]]; then
          while IFS= read -r plugin || [ -n "$plugin" ]; do
            [[ -z "$plugin" || "$plugin" =~ ^[[:space:]]*# ]] && continue
            echo "Installing herdr plugin: $plugin"
            $DRY_RUN_CMD herdr plugin install "$plugin" --yes
          done < "$plugins_file"
        else
          echo "Warning: $plugins_file not found."
        fi
      else
        echo "Warning: herdr command not available in PATH yet."
      fi
    '';
  };
}

