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
        extensions = [
          "rust-src"
          "rust-analyzer"
          "clippy"
          "rustfmt"
          "llvm-tools-preview"
        ];
      })
      awscli2
      bat
      (pkgs.lib.lowPrio rustup)
      bazel-buildtools
      # lowPrio: bazelisk ships an internal `bin/sha256sum` helper that
      # conflicts with uutils-coreutils-noprefix's `sha256sum`; defer to it.
      (pkgs.lib.lowPrio bazelisk)
      buf
      colima
      lima
      curl
      difftastic
      direnv
      docker
      docker-compose
      eza
      fd
      fzf
      btop
      git
      glow
      go
      golangci-lint
      gopls
      kubernetes-helm
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
