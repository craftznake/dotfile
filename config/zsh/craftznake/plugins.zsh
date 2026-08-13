# Import custom configurations
import 0.plugins.before/zsh-eza.zsh
import 0.plugins.before/zsh-vi-mode.zsh
import 0.plugins.before/zsh-mise.zsh
import 0.plugins.before/zsh-abbr.zsh

# Initialize antidote
# Set the root name of the plugins files (.txt and .zsh) antidote will use.
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins

# Ensure the .zsh_plugins.txt file exists so you can add plugins.
[[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt

fpath=($("/opt/homebrew/bin/brew" --prefix)/opt/antidote/share/antidote/functions $fpath)
autoload -Uz antidote

# Generate a new static file whenever .zsh_plugins.txt is updated.
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi

# Source the static plugins file.
source ${zsh_plugins}.zsh

# configure wordchars regonized by the shell
autoload -U select-word-style
select-word-style bash

import 1.plugins.after/zsh-fzf.zsh
import 1.plugins.after/zsh-starship.zsh
import 1.plugins.after/zsh-z.zsh
import 1.plugins.after/zsh-history-substring-search.zsh
import 1.plugins.after/zsh-craftznake.zsh
