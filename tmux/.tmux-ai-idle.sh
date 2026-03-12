#!/bin/bash
# Use the same tmux binary as the running server (snap vs system).
# $TMUX is "socket,pid,index" — resolve the binary from the server PID.
TMUX_BIN="$(readlink -f "/proc/$(echo "$TMUX" | cut -d, -f2)/exe" 2>/dev/null || echo tmux)"
now=$(date +%s)
idle_threshold=3
out=""
colors=("#[fg=#eee8d5,bg=#dc322f,bold]" "#[fg=#eee8d5,bg=#ff6961,bold]")
idx=0

# Map tmux's internal session IDs ($N) to the chooser's one-based order.
session_order=1
session_display_idx=()
while IFS='	' read -r sid _; do
  sid_num="${sid#\$}"
  session_display_idx[$sid_num]=$session_order
  session_order=$((session_order + 1))
done < <("$TMUX_BIN" list-sessions -F "#{session_id}	#{session_name}" 2>/dev/null | sort -k2,2)

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

# Track which windows have an idle AI pane.
declare -A idle_windows   # window_id -> session_id
declare -A all_windows    # all window_ids seen

# Use list-panes (not list-windows) so non-active panes are checked too.
while IFS='	' read -r window_id session_id cmd tty; do
  all_windows[$window_id]=1
  [ -n "${idle_windows[$window_id]}" ] && continue
  if is_ai_window "$cmd" "$tty"; then
    # Per-pane idle: use the TTY device mtime (last program output).
    tty_mtime=$(stat -c %Y "$tty" 2>/dev/null || echo "$now")
    if [ $((now - tty_mtime)) -gt "$idle_threshold" ]; then
      idle_windows[$window_id]="$session_id"
    fi
  fi
done < <("$TMUX_BIN" list-panes -a -F "#{window_id}	#{session_id}	#{pane_current_command}	#{pane_tty}")

for window_id in "${!all_windows[@]}"; do
  if [ -n "${idle_windows[$window_id]}" ]; then
    "$TMUX_BIN" set-window-option -q -t "$window_id" @ai_idle 1 >/dev/null 2>&1
    sid="${idle_windows[$window_id]#\$}"
    display_idx="${session_display_idx[$sid]:-$sid}"
    out="$out${colors[$((idx % 2))]} $display_idx ⏳ "
    idx=$((idx + 1))
  else
    "$TMUX_BIN" set-window-option -q -u -t "$window_id" @ai_idle >/dev/null 2>&1
  fi
done

[ -n "$out" ] && printf ' %s ' "$out"
