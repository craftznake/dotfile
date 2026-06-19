# Register related knife commands
if command -v knife >/dev/null 2>&1; then
    eval "$(knife completion)"

    if [[ -f ~/.knife/shell/shell.zsh ]]; then
        zmodload zsh/stat

        typeset -g LAST_ENV_MTIME=0
        typeset -g ENV_SHARE_FILE="$HOME/.knife/shell/shell.zsh"

        _sync_knife() {
            # CASE 1: File is deleted -> Wipe variables
            if [[ ! -f "$ENV_SHARE_FILE" ]]; then
                if [[ "$LAST_ENV_MTIME" -ne 0 ]]; then
                    unset AWS_PROFILE AWS_REGION
                    LAST_ENV_MTIME=0
                fi
                return 0
            fi

            local current_mtime
            stat -A current_mtime +mtime "$ENV_SHARE_FILE" 2>/dev/null

            # CASE 2 & 3: File created or modified -> Re-source
            if [[ "$current_mtime" -ne "$LAST_ENV_MTIME" ]]; then
                # Clean slate before sourcing new ones
                unset AWS_PROFILE AWS_REGION

                source "$ENV_SHARE_FILE"
                LAST_ENV_MTIME=$current_mtime
            fi
        }

        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _sync_knife
    fi
fi

# Register related aws commands suggestions
if command -v aws_completer >/dev/null 2>&1; then
    complete -C "$(where aws_completer)" aws
fi


# Register related aws commands suggestions
if command -v acli >/dev/null 2>&1; then
    eval "$(acli completion zsh)"
fi

