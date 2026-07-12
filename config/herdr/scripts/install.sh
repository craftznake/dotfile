#!/bin/sh

while read -r plugin; do
    [[ -z "$plugin" || "$plugin" =~ ^# ]] && continue
    echo "Install $plugin"
    herdr plugin install "$plugin" --yes
done < ~/.config/herdr/plugins.txt
