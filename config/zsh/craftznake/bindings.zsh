# Function to edit the current command line in nvim
edit_command_line() {
    # Save the current command line (left and right of the cursor) to a temporary file
    TMP_FILE=$(mktemp)
    echo "$BUFFER" > "$TMP_FILE"  # Combine left and right buffers

    # Open the temporary file in nvim
    $EDITOR $TMP_FILE

    # Load the edited content back into the command line buffer
    # Read content from temporary file
    BUFFER=$(<"$TMP_FILE")
    # Clean up
    rm "$TMP_FILE"

    # Set the cursor position to the end of the buffer
    CURSOR=${#BUFFER}
}

# # Register the function as a Zsh widget
zle -N edit_command_line

# # Bind Alt+V to the edit_command_line widget
bindkey -M viins '^[v' edit_command_line  # In insert mode
bindkey -M vicmd '^[v' edit_command_line   # In command mode
