{
  pkgs,
  lib,
  username,
  config,
  ...
}:
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

  # Link an out-of-store directory file by file.
  #
  # `recursive = true` together with `mkOutOfStoreSymlink` only puts a symlink
  # to the directory in the store; the file list is expanded by `lndir` at
  # *build* time. Adding, removing or renaming a file therefore does not change
  # any derivation and Nix happily reuses the previously built
  # `home-manager-files` (leaving dangling links behind). Walking the tree here
  # puts the file list into the evaluation, so the link set is regenerated,
  # while each file stays a live symlink into the repo.
  liveTree =
    target: source:
    let
      walk =
        rel:
        let
          dir = if rel == "" then source else "${source}/${rel}";
        in
        lib.concatLists (
          lib.mapAttrsToList (
            name: type:
            let
              relPath = if rel == "" then name else "${rel}/${name}";
            in
            if type == "directory" then
              walk relPath
            else
              [
                (lib.nameValuePair "${target}/${relPath}" {
                  source = config.lib.file.mkOutOfStoreSymlink "${source}/${relPath}";
                  target = "${target}/${relPath}";
                })
              ]
          ) (builtins.readDir dir)
        );
    in
    builtins.listToAttrs (walk "");
in
{
  programs.zsh = {
    enable = true;
    sessionVariables = {
      EDITOR = "nvim";
      CLICOLOR = 1;
    };
    initContent = ''
      source ~/.config/zsh/index.zsh
      if [[ $(uname -m) == 'arm64' ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
    '';
    envExtra = ''
      alias tf='terraform'
      alias k="kubectl"
      alias vim="nvim"
    '';
  };
  home.file = {
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
    "vimrc" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotconfigs}/config/vim/vimrc";
      target = ".vimrc";
    };
    "wezterm" = {
      source = "${dotconfigs}/config/wezterm";
      target = ".config/wezterm";
      recursive = true;
    };
    "ghostty" = {
      source = "${dotconfigs}/config/ghostty";
      target = ".config/ghostty";
      recursive = true;
    };
    "zsh_plugins" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotconfigs}/config/antidote-plugin.txt";
      target = ".zsh_plugins.txt";
    };
    "starship" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotconfigs}/config/starship.toml";
      target = ".config/starship.toml";
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
    "rex_config" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotconfigs}/config/rex/init.lua";
      target = ".config/rex/init.lua";
      force = true;
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
  }
  // liveTree ".config/aerospace" "${dotconfigs}/config/aerospace"
  // liveTree ".config/zsh" "${dotconfigs}/config/zsh"
  // liveTree ".scripts" "${dotconfigs}/scripts";
}
