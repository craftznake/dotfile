# mise is NOT activated by default (activation adds startup cost and a shell
# hook). Run `load_mise` to activate it in the current shell on demand.
if type "mise" >/dev/null 2>&1; then
    load_mise() {
        eval "$(mise activate zsh)"
        echo "mise activated."
    }
fi
