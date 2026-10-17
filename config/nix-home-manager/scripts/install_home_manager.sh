#!/bin/sh
if command -v home-manager >/dev/null 2>&1; then
    echo "home-manager exists."
else
    echo "home-manager does not exist, installing..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install
fi
