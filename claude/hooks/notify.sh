#!/bin/bash
# Claude Code notification hook — sends OSC 9 desktop notification through
# tmux DCS passthrough so it reaches the local Ghostty terminal over SSH.
#
# Requires: set -g allow-passthrough on   (tmux.conf)

# Resolve tmux binary from the running server (snap vs system).
if [ -n "$TMUX" ]; then
  TMUX_BIN="$(readlink -f "/proc/$(echo "$TMUX" | cut -d, -f2)/exe" 2>/dev/null || echo tmux)"
else
  TMUX_BIN=tmux
fi

# Parse notification title from stdin JSON (Claude Code pipes hook data).
message="Claude Code needs attention"
if read -r -t 1 input 2>/dev/null; then
  title=$(printf '%s' "$input" | jq -r '.title // empty' 2>/dev/null)
  [ -n "$title" ] && message="$title"
fi

# Find the pane TTY so we can write the escape sequence to the terminal.
if [ -n "$TMUX" ]; then
  tty=$("$TMUX_BIN" display-message -p '#{pane_tty}' 2>/dev/null)
fi
: "${tty:=/dev/tty}"

# Send OSC 9 notification.
if [ -n "$TMUX" ]; then
  # Wrap in DCS passthrough so tmux forwards it to the outer terminal (Ghostty).
  printf '\ePtmux;\e\e]9;%s\a\e\\' "$message" > "$tty" 2>/dev/null
else
  printf '\e]9;%s\a' "$message" > "$tty" 2>/dev/null
fi
