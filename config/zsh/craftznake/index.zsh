if [[ -f "$ZSH_ROOT/utils.zsh" ]]; then
    source "$ZSH_ROOT/utils.zsh"
fi

if [[ -f "$ZSH_ROOT/options.zsh" ]]; then
    source "$ZSH_ROOT/options.zsh"
fi

if [[ -f "$ZSH_ROOT/paths.zsh" ]]; then
    source "$ZSH_ROOT/paths.zsh"
fi

if [[ -f "$ZSH_ROOT/plugins.zsh" ]]; then
    source "$ZSH_ROOT/plugins.zsh"
fi

if [[ -f "$ZSH_ROOT/bindings.zsh" ]]; then
    source "$ZSH_ROOT/bindings.zsh"
fi

if [[ -f "$ZSH_ROOT/alias.zsh" ]]; then
    source "$ZSH_ROOT/alias.zsh"
fi

if [[ -f "$ZSH_ROOT/abbrs.zsh" ]]; then
    source "$ZSH_ROOT/abbrs.zsh"
fi

if [[ -f "$ZSH_ROOT/themes.zsh" ]]; then
    source "$ZSH_ROOT/themes.zsh"
fi

if [[ -f "$HOME/secret/envs.zsh" ]]; then
    source "$HOME/secret/envs.zsh"
fi
