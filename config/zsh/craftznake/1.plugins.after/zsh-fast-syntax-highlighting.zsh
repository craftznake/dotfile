# Disable hightlight on long command, we need to run this in zsh-defer, to make this execute after kind:defer
zsh-defer -c "
    ZSH_HIGHLIGHT_MAXLENGTH=300
"
