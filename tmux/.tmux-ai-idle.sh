#!/bin/bash
now=$(date +%s)
idle_threshold=3
out=""

is_ai_window() {
  local cmd="$1"
  local tty="$2"

  if [ "$cmd" = "claude" ] || [ "$cmd" = "codex" ]; then
    return 0
  fi

  # Codex frequently appears as `node`, so inspect the TTY command lines.
  if [ "$cmd" = "node" ] && ps -t "${tty#/dev/}" -o args= 2>/dev/null | grep -Eiq '(^|[ /])(claude|codex)([[:space:]]|$)'; then
    return 0
  fi

  return 1
}

while IFS='	' read -r window_id name cmd tty activity; do
  if is_ai_window "$cmd" "$tty" && [ $((now - activity)) -gt "$idle_threshold" ]; then
    tmux set-window-option -q -t "$window_id" @ai_idle 1 >/dev/null 2>&1
    [ -n "$out" ] && out="$out | "
    out="$out$name ⏳"
  else
    tmux set-window-option -q -u -t "$window_id" @ai_idle >/dev/null 2>&1
  fi
done < <(tmux list-windows -a -F "#{window_id}	#{session_name}:#{window_name}	#{pane_current_command}	#{pane_tty}	#{window_activity}")
[ -n "$out" ] && printf ' %s ' "$out"
