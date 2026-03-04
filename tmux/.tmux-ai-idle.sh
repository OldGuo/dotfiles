#!/bin/bash
now=$(date +%s)
idle_threshold=3
out=""
colors=("#[fg=#eee8d5,bg=#dc322f,bold]" "#[fg=#eee8d5,bg=#ff6961,bold]")
idx=0

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

while IFS='	' read -r window_id session_id session cmd tty activity pane_path; do
  if is_ai_window "$cmd" "$tty" && [ $((now - activity)) -gt "$idle_threshold" ]; then
    tmux set-window-option -q -t "$window_id" @ai_idle 1 >/dev/null 2>&1
    branch=$(cd "$pane_path" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
    sid="${session_id#\$}"
    out="$out${colors[$((idx % 2))]} ($sid) $session${branch:+ [$branch]} ⏳ "
    idx=$((idx + 1))
  else
    tmux set-window-option -q -u -t "$window_id" @ai_idle >/dev/null 2>&1
  fi
done < <(tmux list-windows -a -F "#{window_id}	#{session_id}	#{session_name}	#{pane_current_command}	#{pane_tty}	#{window_activity}	#{pane_current_path}")
[ -n "$out" ] && printf ' %s ' "$out"
