eval "$(zoxide init zsh)"

function cd() {
    __zoxide_z "$@"
}
