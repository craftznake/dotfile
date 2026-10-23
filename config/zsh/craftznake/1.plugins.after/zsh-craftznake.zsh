# Register related knife commands
if command -v knife >/dev/null 2>&1; then
    eval "$(COMPLETE=zsh knife)"
fi

# Register related aws commands suggestions
if command -v aws_completer >/dev/null 2>&1; then
    complete -C "$(where aws_completer)" aws
fi

if command -v terraform >/dev/null 2>&1; then
    complete -C $(where terraform) terraform
fi

if command -v kind >/dev/null 2>&1; then
    source <(kind completion zsh)
fi

if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion zsh)
fi

if command -v herdr >/dev/null 2>&1; then
    source <(herdr completion zsh)
fi
