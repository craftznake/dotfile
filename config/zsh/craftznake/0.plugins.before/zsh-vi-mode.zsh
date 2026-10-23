function zvm_config() {
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLOCK
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
    ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE

    ZVM_VI_HIGHLIGHT_FOREGROUND=#faf4ed
    ZVM_VI_HIGHLIGHT_BACKGROUND=#907aa9
    ZVM_VI_HIGHLIGHT_EXTRASTYLE=bold,underline
}

# Inline (non-popup) history search that accepts glob patterns, e.g. `e*z*s*h*`
# for *Users/dat.nguyen/.config/zsh/.../zsh-history-substring-search.zsh*.
# Matching is unanchored, so no leading `*` is needed (and on this zsh a
# leading `*` actually makes the search fail).
# Must be applied after zvm init: zsh-vi-mode re-applies its own insert-mode
# keymap during init and would otherwise restore plain substring isearch.
function zvm_after_init() {
    bindkey -M viins '^R' history-incremental-pattern-search-backward
    bindkey -M viins '^S' history-incremental-pattern-search-forward
    bindkey -M emacs '^R' history-incremental-pattern-search-backward
    bindkey -M emacs '^S' history-incremental-pattern-search-forward
}
