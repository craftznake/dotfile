#!/bin/sh
# Swap the focused Herdr pane one step in a direction; when it already sits on
# that edge, rebuild the split along the other axis instead of doing nothing.
#
#   pane-move.sh left|down|up|right        (bound to ctrl+shift+hjkl)
#
# Herdr passes HERDR_BIN_PATH and HERDR_ACTIVE_PANE_ID to keybind commands, so
# this always acts on the pane the key was pressed in.
set -eu

dir=${1:-}
case $dir in
    left|down|up|right) ;;
    *) echo "usage: pane-move.sh left|down|up|right" >&2; exit 64 ;;
esac

bin=${HERDR_BIN_PATH:-herdr}
pane=${HERDR_ACTIVE_PANE_ID:-}
if [ -z "$pane" ]; then
    echo "pane-move: HERDR_ACTIVE_PANE_ID is not set" >&2
    exit 1
fi

json_id() { # json_id <field> -> first value of "field":"..." on stdin
    sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p" | head -1
}

neighbour() { # neighbour <direction> -> pane id on that side, empty if none
    "$bin" pane neighbor --pane "$pane" --direction "$1" 2>/dev/null |
        json_id neighbor_pane_id
}

# A pane in the way: an ordinary swap moves this pane into its place.
if [ -n "$(neighbour "$dir")" ]; then
    "$bin" pane swap --pane "$pane" --direction "$dir" >/dev/null
    exit 0
fi

# Nothing in that direction: find the pane on the other axis, so A|B pressed
# with "down" becomes A over B, and A over B pressed with "right" becomes A|B.
case $dir in
    down|up) axes="left right" ;;
    *)       axes="up down" ;;
esac
other=
for axis in $axes; do
    other=$(neighbour "$axis")
    [ -n "$other" ] && break
done
[ -n "$other" ] || exit 0   # lone pane on the tab: nothing to re-split

# The moved pane has to land on the down/right side of the pane that stays, so
# it is swapped with a throwaway split of that pane, then the throwaway closes.
if [ "$dir" = down ] || [ "$dir" = right ]; then
    stays=$other moves=$pane side=$dir
else
    stays=$pane moves=$other
    if [ "$dir" = up ]; then side=down; else side=right; fi
fi

spare=$("$bin" pane split "$stays" --direction "$side" --no-focus | json_id pane_id)
if [ -z "$spare" ]; then
    echo "pane-move: could not create the temporary split" >&2
    exit 1
fi

"$bin" pane swap --source-pane "$moves" --target-pane "$spare" >/dev/null
"$bin" pane close "$spare" >/dev/null
