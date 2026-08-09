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
      (rust-bin.stable.latest.default.override { extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" "llvm-tools-preview" ]; })
      awscli2
      bat
      bazel-buildtools
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
      herdr
      istioctl
      jj-starship
      jq
      jujutsu
      k9s
      kind
      kubectl
      lazygit
      lua-language-server
      mise
      mpv
      neovim
      nodejs_24
      protobuf
      protoc-gen-go
      protoc-gen-go-grpc
      python3
      ripgrep
      starship
      terraform
      terraformer
      tmux
      tpack
      tree
      tree-sitter
      uutils-coreutils-noprefix
      watchman
      wdiff
      websocat
      wget
      write-good
      yq
      zig
      zoxide
      zsh-abbr
    ];
  };
}
