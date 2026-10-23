#!/usr/bin/env bash
# rex jump — fuzzy-pick a pane, tab, or session and go there.
#
# Opened by the `jump` action in init.lua (prefix g). It runs in a floating
# terminal layer, so the picker overlays the current tab and closes itself
# when a choice is made or the picker is cancelled with Escape.
#
# Installed at ~/.config/rex/jump.sh by home-manager; edit the copy in
# ~/dotfile/config/rex/.
#
# Focus uses server-side commands (rex block focus / rex window focus), which
# need no extra permissions. Switching to another session needs the app's
# session.select action, which requires Remote Control (Settings > Rex Server);
# without it you land in the right pane of that session but the app stays put.

set -uo pipefail

# Blocks may start without the nix profile on PATH, and Rex sets REX_BIN_DIR
# but doesn't always leave it on PATH.
[ -n "${REX_BIN_DIR:-}" ] && PATH="${REX_BIN_DIR}:${PATH}"
PATH="${HOME}/.nix-profile/bin:/opt/homebrew/bin:${PATH:-/usr/bin:/bin}"
export PATH

rex=rex
tmp="${TMPDIR:-/tmp}/rex-jump.$$"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

# Rows: kind, session, window, block, display text.
build_rows() {
  rm -rf "$tmp"; mkdir -p "$tmp" || return 1

  "$rex" ls --json 2>/dev/null |
    jq -r '.sessions[] | [.session_id, .label] | @tsv' >"$tmp/sessions" 2>/dev/null

  : >"$tmp/rows"
  local sid slabel
  while IFS=$'\t' read -r sid slabel; do
    [ -n "${sid:-}" ] || continue
    printf 'session\t%s\t\t\t%s\n' "$sid" "$slabel" >>"$tmp/rows"
    "$rex" api call session.view "{\"session_id\":\"$sid\"}" 2>/dev/null |
      jq -r --arg sid "$sid" --arg s "$slabel" '
        .windows[]
        | .window_id as $w
        | .label as $wl
        | ("window\t" + $sid + "\t" + $w + "\t\t" + ($s + " / " + $wl)),
          (.layers[] | select(.kind == "tiled") | .blocks[]
            | ("block\t" + $sid + "\t" + $w + "\t" + .block_id + "\t"
               + ($s + " / " + $wl + " / ")))
      ' 2>/dev/null >>"$tmp/rows"
  done <"$tmp/sessions"

  # Drop the picker's own pane.
  if [ -n "${REX_BLOCK:-}" ]; then
    grep -v -F "${REX_BLOCK}" "$tmp/rows" >"$tmp/rows.filtered" ||
      : >"$tmp/rows.filtered"
    mv "$tmp/rows.filtered" "$tmp/rows"
  fi

  # Terminal titles are one call per block, so ask for them in parallel.
  : >"$tmp/titles"
  cut -f1,2,3,4 "$tmp/rows" | awk -F'\t' '$1 == "block" { print $4 }' |
    sort -u |
    xargs -P 8 -n 1 sh -c \
      'printf "%s\t%s\n" "$1" "$("'"$rex"'" block call -b "$1" title 2>/dev/null | jq -r ".title // empty")"' \
      sh >"$tmp/titles" 2>/dev/null

  awk -F'\t' '
    FNR == NR { title[$1] = $2; next }
    {
      kind = $1; sid = $2; wid = $3; bid = $4; label = $5
      if (kind == "session")      text = "SESSION  " label
      else if (kind == "window")  text = "TAB      " label
      else {
        t = title[bid]
        if (t == "") t = "pane " substr(bid, length(bid) - 5)
        text = "PANE     " label t
      }
      printf "%s\t%s\t%s\t%s\t%s\n", text, kind, sid, wid, bid
    }
  ' "$tmp/titles" "$tmp/rows"
}

select_session() {
  local sid=$1 client
  [ -n "${REX_SESSION:-}" ] && [ "$sid" = "$REX_SESSION" ] && return 0
  client=$("$rex" client ls --json 2>/dev/null |
    jq -r '.clients[] | select(.info.kind == "app") | .client_id' 2>/dev/null | head -1)
  [ -n "${client:-}" ] || return 0
  "$rex" -C "$client" do session.select session_id="$sid" >/dev/null 2>&1 || return 0
}

# The display text is field 1 and the only field searched; ids follow it.
fzf_args=(--delimiter='\t' --with-nth=1 --nth=1 --height=100% --reverse
  --no-multi --no-info --pointer='▶' --prompt='jump> '
  --header='panes, tabs and sessions  ·  enter to jump, esc to close')

if [ -n "${JUMP_FILTER:-}" ]; then
  choice=$(build_rows | fzf "${fzf_args[@]}" --filter="$JUMP_FILTER" | head -1)
elif [ -n "${JUMP_LIST:-}" ]; then
  build_rows
  exit 0
else
  choice=$(build_rows | fzf "${fzf_args[@]}")
fi

[ -n "${choice:-}" ] || exit 0

# JUMP_ECHO=1 makes the test harness print what would be jumped to.
if [ -n "${JUMP_ECHO:-}" ]; then
  printf '%s\n' "$choice"
  exit 0
fi

IFS=$'\t' read -r _text kind sid wid bid <<<"$choice"

case "$kind" in
  session)
    select_session "$sid"
    "$rex" window focus -s "$sid" 1 >/dev/null 2>&1
    ;;
  window)
    select_session "$sid"
    "$rex" window focus -s "$sid" "$wid" >/dev/null 2>&1
    ;;
  block)
    select_session "$sid"
    "$rex" block focus -s "$sid" "$bid" >/dev/null 2>&1
    ;;
esac
