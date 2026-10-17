# Prevent duplicate entries in PATH
typeset -U path PATH

# Define new paths to add
local new_paths=(
    "$HOME/.cargo/bin"
    "$HOME/.opencode/bin"
    "$HOME/.local/bin"
    "${GOPATH:-$(go env GOPATH 2>/dev/null)}/bin"
    "$HOME/.scripts"
)

# Only add paths if the directory exists
for dir in $new_paths; do
    [[ -d "$dir" ]] && path+=("$dir")
done
