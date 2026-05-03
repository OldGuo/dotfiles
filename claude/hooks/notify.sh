#!/bin/bash
# Claude Code notification hook — sends OSC 9 desktop notification through
# tmux DCS passthrough so it reaches the local Ghostty terminal over SSH.
#
# Requires: set -g allow-passthrough on   (tmux.conf)

# Resolve tmux binary from the running server when Linux exposes it.
# macOS has no /proc, so fall back to the tmux on PATH there.
tmux_binary() {
  local pid exe

  if [ -n "$TMUX" ]; then
    pid="$(printf '%s' "$TMUX" | cut -d, -f2)"
    if [ -n "$pid" ] && [ -e "/proc/$pid/exe" ]; then
      exe="$(readlink -f "/proc/$pid/exe" 2>/dev/null)"
      if [ -n "$exe" ]; then
        printf '%s\n' "$exe"
        return
      fi
    fi
  fi

  command -v tmux 2>/dev/null || printf 'tmux\n'
}

TMUX_BIN="$(tmux_binary)"

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
  { printf '\ePtmux;\e\e]9;%s\a\e\\' "$message" > "$tty"; } 2>/dev/null || true
else
  { printf '\e]9;%s\a' "$message" > "$tty"; } 2>/dev/null || true
fi
