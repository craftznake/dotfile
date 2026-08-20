# It's safe to disable flow control, as flow control is for:
#   - pausing output to the terminal
#   - stopping the terminal from sending input to the program
# and we don't need that here.
# Disabling flow control allows us to use Ctrl+S for forward search
stty -ixon


# hook function to be called after the plugin is loaded
bindkey -M viins '^[[A' history-substring-search-up
bindkey -M viins '^[[B' history-substring-search-down

# Bind k and j for vi mode
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Configuration options
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=magenta,fg=white,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'
HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'
