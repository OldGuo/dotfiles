#!/bin/bash
now=$(date +%s)
out=""
while IFS='	' read -r name cmd activity; do
  if [ "$cmd" = "claude" ] && [ $((now - activity)) -gt 10 ]; then
    [ -n "$out" ] && out="$out | "
    out="$out$name ⏳"
  fi
done < <(tmux list-windows -a -F "#{session_name}:#{window_name}	#{pane_current_command}	#{window_activity}")
[ -n "$out" ] && printf ' %s ' "$out"
