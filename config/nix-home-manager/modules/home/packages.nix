{ pkgs, ... }:
##################################
#
# Homemanager managed packages
#
#################################
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  home = {
    packages = with pkgs; [
      (rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" "llvm-tools-preview" ];
      })
      amp-cli
      ascii-image-converter
      atuin
      awscli2
      bat
      bazel-buildtools
      bazel_7
      bazelisk
      buf
      colima
      curl
      difftastic
      direnv
      docker
      docker-compose
      eza
      fd
      fzf
      git
      go
      golangci-lint
      gopls
      gotools
      jj-starship
      jujutsu
      krabby
      kubectl
      lazygit
      lua-language-server
      minikube
      mise
      mpv
      neovim
      nodejs_24
      protobuf
      protobuf
      protoc-gen-go
      protoc-gen-go-grpc
      python3
      ripgrep
      starship
      terraform
      terraformer
      tmux
      herdr
      tpack
      tpack
      tree
      tree-sitter
      uutils-coreutils-noprefix
      wdiff
      websocat
      wget
      write-good
      youtube-tui
      yt-dlp
      watchman
      yq
      zig
      zoxide
      zsh-abbr
    ];
  };
}
