#!/bin/bash
# Use the same tmux binary as the running server (snap vs system).
# $TMUX is "socket,pid,index" — resolve the binary from the server PID.
TMUX_BIN="$(readlink -f "/proc/$(echo "$TMUX" | cut -d, -f2)/exe" 2>/dev/null || echo tmux)"
now=$(date +%s)
idle_threshold=15
colors=("#[fg=#eee8d5,bg=#dc322f,bold]" "#[fg=#eee8d5,bg=#ff6961,bold]")

# Map tmux's internal session IDs ($N) to the chooser's one-based order and name.
session_order=1
declare -A session_display_idx
declare -A session_names
while IFS='	' read -r sid sname; do
  sid_num="${sid#\$}"
  session_display_idx[$sid_num]=$session_order
  session_names[$sid_num]="$sname"
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
declare -A idle_paths     # window_id -> pane_current_path
declare -A all_windows    # window_id -> current @ai_idle value

# Use list-panes (not list-windows) so non-active panes are checked too.
# Include @ai_idle to skip no-op set-window-option calls.
while IFS='	' read -r window_id session_id cmd tty pane_path ai_idle; do
  all_windows[$window_id]="$ai_idle"
  [ -n "${idle_windows[$window_id]}" ] && continue
  if is_ai_window "$cmd" "$tty"; then
    # Per-pane idle: use the TTY device mtime (last program output).
    tty_mtime=$(stat -c %Y "$tty" 2>/dev/null || echo "$now")
    if [ $((now - tty_mtime)) -gt "$idle_threshold" ]; then
      idle_windows[$window_id]="$session_id"
      idle_paths[$window_id]="$pane_path"
    fi
  fi
done < <("$TMUX_BIN" list-panes -a -F "#{window_id}	#{session_id}	#{pane_current_command}	#{pane_tty}	#{pane_current_path}	#{@ai_idle}")

# Build both long (session_name branch) and short (index) formats.
long_out=""
short_out=""
long_width=0
idx=0

for window_id in "${!all_windows[@]}"; do
  if [ -n "${idle_windows[$window_id]}" ]; then
    # Only set if not already marked idle.
    [ "${all_windows[$window_id]}" != "1" ] && \
      "$TMUX_BIN" set-window-option -q -t "$window_id" @ai_idle 1 >/dev/null 2>&1
    sid="${idle_windows[$window_id]#\$}"
    display_idx="${session_display_idx[$sid]:-$sid}"
    sname="${session_names[$sid]:-}"
    branch=$(cd "${idle_paths[$window_id]}" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)

    label="(${display_idx}) ${sname}${branch:+ $branch}"
    color="${colors[$((idx % 2))]}"
    long_out="${long_out}${color} ⏳ ${label} "
    short_out="${short_out}${color} ⏳ (${display_idx}) "
    # +6: leading space (1) + ⏳ (2 columns) + space after emoji (1) + trailing space (1) + space before emoji (1)
    long_width=$((long_width + ${#label} + 6))
    idx=$((idx + 1))
  else
    # Only unset if currently marked idle.
    [ "${all_windows[$window_id]}" = "1" ] && \
      "$TMUX_BIN" set-window-option -q -u -t "$window_id" @ai_idle >/dev/null 2>&1
  fi
done

[ "$idx" -eq 0 ] && exit 0

# Decide format based on available space (windows take precedent).
client_width=$("$TMUX_BIN" display -p '#{client_width}' 2>/dev/null || echo 200)
win_list_width=0
while IFS= read -r wname; do
  win_list_width=$((win_list_width + ${#wname} + 5))
done < <("$TMUX_BIN" list-windows -F "#{window_name}" 2>/dev/null)
# 48 = status-left-length, 25 ≈ datetime portion of status-right
available=$((client_width - 48 - win_list_width - 25))

if [ "$long_width" -le "$available" ]; then
  printf ' %s ' "$long_out"
else
  printf ' %s ' "$short_out"
fi
