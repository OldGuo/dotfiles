#!/bin/bash
# Use the same tmux binary as the running server (snap vs system).
# $TMUX is "socket,pid,index" — resolve the binary from the server PID.
TMUX_BIN="$(readlink -f "/proc/$(echo "$TMUX" | cut -d, -f2)/exe" 2>/dev/null || echo tmux)"

# Snap updates can wipe the private /tmp that holds the socket.
# Recreate the directory so the server can re-bind.
if [ -n "$TMUX" ]; then
  _socket="${TMUX%%,*}"
  _socket_dir="$(dirname "$_socket")"
  [ -d "$_socket_dir" ] || mkdir -p "$_socket_dir" 2>/dev/null
fi

now=$(date +%s)
idle_threshold=15
idle_colors=("#[fg=#eee8d5,bg=#dc322f,bold]" "#[fg=#eee8d5,bg=#ff6961,bold]")
thinking_colors=("#[fg=#002b36,bg=#ffd700,bold]" "#[fg=#002b36,bg=#f0ad4e,bold]")

# Map tmux session IDs to one-based display index and name (for status-right labels).
session_order=1
declare -A session_display_idx
declare -A session_names
while IFS='|' read -r sid sname; do
  sid_num="${sid#\$}"
  session_display_idx[$sid_num]=$session_order
  session_names[$sid_num]="$sname"
  session_order=$((session_order + 1))
done < <("$TMUX_BIN" list-sessions -F "#{session_id}|#{session_name}" 2>/dev/null)

is_ai_window() {
  local cmd="$1"
  local tty="$2"

  if [ "$cmd" = "claude" ] || [ "$cmd" = "codex" ] || [ "$cmd" = "agent" ] || [ "$cmd" = "cursor-agent" ]; then
    return 0
  fi

  # Some AI CLIs may appear as `node`, so inspect the TTY command lines.
  if [ "$cmd" = "node" ] && ps -t "${tty#/dev/}" -o args= 2>/dev/null | grep -Eiq '(^|[ /])(claude|codex|agent|cursor-agent)([[:space:]]|$)'; then
    return 0
  fi

  return 1
}

# Track which windows have an idle or thinking AI pane.
declare -A idle_windows      # window_id -> session_id
declare -A thinking_windows  # window_id -> session_id
declare -A idle_paths        # window_id -> pane_current_path
declare -A all_windows       # window_id -> current @ai_idle value
declare -A all_windows_think # window_id -> current @ai_thinking value

# Use list-panes (not list-windows) so non-active panes are checked too.
# Include @ai_idle and @ai_thinking to skip no-op set-window-option calls.
while IFS='|' read -r window_id session_id cmd tty pane_path ai_idle ai_thinking; do
  all_windows[$window_id]="$ai_idle"
  all_windows_think[$window_id]="$ai_thinking"
  [ -n "${idle_windows[$window_id]}" ] || [ -n "${thinking_windows[$window_id]}" ] && continue
  if is_ai_window "$cmd" "$tty"; then
    # Per-pane idle: use the TTY device mtime (last program output).
    tty_mtime=$(stat -c %Y "$tty" 2>/dev/null || echo "$now")
    if [ $((now - tty_mtime)) -gt "$idle_threshold" ]; then
      idle_windows[$window_id]="$session_id"
      idle_paths[$window_id]="$pane_path"
    else
      thinking_windows[$window_id]="$session_id"
    fi
  fi
done < <("$TMUX_BIN" list-panes -a -F "#{window_id}|#{session_id}|#{pane_current_command}|#{pane_tty}|#{pane_current_path}|#{@ai_idle}|#{@ai_thinking}")

# Update @ai_idle and @ai_thinking window options.
declare -A newly_idle
for window_id in "${!all_windows[@]}"; do
  if [ -n "${idle_windows[$window_id]}" ]; then
    if [ "${all_windows[$window_id]}" != "1" ]; then
      "$TMUX_BIN" set-window-option -q -t "$window_id" @ai_idle 1 >/dev/null 2>&1
      newly_idle[$window_id]=1
    fi
    [ "${all_windows_think[$window_id]}" = "1" ] && \
      "$TMUX_BIN" set-window-option -q -u -t "$window_id" @ai_thinking >/dev/null 2>&1
  elif [ -n "${thinking_windows[$window_id]}" ]; then
    [ "${all_windows_think[$window_id]}" != "1" ] && \
      "$TMUX_BIN" set-window-option -q -t "$window_id" @ai_thinking 1 >/dev/null 2>&1
    [ "${all_windows[$window_id]}" = "1" ] && \
      "$TMUX_BIN" set-window-option -q -u -t "$window_id" @ai_idle >/dev/null 2>&1
  else
    [ "${all_windows[$window_id]}" = "1" ] && \
      "$TMUX_BIN" set-window-option -q -u -t "$window_id" @ai_idle >/dev/null 2>&1
    [ "${all_windows_think[$window_id]}" = "1" ] && \
      "$TMUX_BIN" set-window-option -q -u -t "$window_id" @ai_thinking >/dev/null 2>&1
  fi
done

# Set/unset @session_ai_idle and @session_ai_thinking per session for choose-tree styling.
declare -A idle_sessions
declare -A thinking_sessions
for wid in "${!idle_windows[@]}"; do
  idle_sessions["${idle_windows[$wid]}"]=1
done
for wid in "${!thinking_windows[@]}"; do
  thinking_sessions["${thinking_windows[$wid]}"]=1
done
for sid_num in "${!session_display_idx[@]}"; do
  sid="\$$sid_num"
  if [ -n "${idle_sessions[$sid]}" ]; then
    "$TMUX_BIN" set-option -q -t "$sid" @session_ai_idle 1 >/dev/null 2>&1
  else
    "$TMUX_BIN" set-option -q -u -t "$sid" @session_ai_idle >/dev/null 2>&1
  fi
  if [ -n "${thinking_sessions[$sid]}" ]; then
    "$TMUX_BIN" set-option -q -t "$sid" @session_ai_thinking 1 >/dev/null 2>&1
  else
    "$TMUX_BIN" set-option -q -u -t "$sid" @session_ai_thinking >/dev/null 2>&1
  fi
done

# Build idle label for each window (shared by status-right and notifications).
declare -A idle_labels      # window_id -> "(idx) name branch"
declare -A idle_short_labels # window_id -> "(idx)"
for window_id in "${!idle_windows[@]}"; do
  sid="${idle_windows[$window_id]#\$}"
  display_idx="${session_display_idx[$sid]:-$sid}"
  sname="${session_names[$sid]:-}"
  branch=$(cd "${idle_paths[$window_id]}" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
  idle_labels[$window_id]="(${display_idx}) ${sname}${branch:+ $branch}"
  idle_short_labels[$window_id]="(${display_idx})"
done

# Build thinking label for each window (session number only).
declare -A thinking_labels
for window_id in "${!thinking_windows[@]}"; do
  sid="${thinking_windows[$window_id]#\$}"
  display_idx="${session_display_idx[$sid]:-$sid}"
  thinking_labels[$window_id]="(${display_idx})"
done

# Send desktop notification for windows that just became idle.
if [ "${#newly_idle[@]}" -gt 0 ]; then
  notif_msg="❕ AI Idle"
  for wid in "${!newly_idle[@]}"; do
    notif_msg="${notif_msg}
 • ${idle_labels[$wid]}"
  done
  while IFS= read -r ctty; do
    printf '\ePtmux;\e\e]9;%s\a\e\\' "$notif_msg" > "$ctty" 2>/dev/null
  done < <("$TMUX_BIN" list-clients -F '#{client_tty}' 2>/dev/null)
fi

# Output thinking + idle labels to status-right.
[ "${#idle_windows[@]}" -eq 0 ] && [ "${#thinking_windows[@]}" -eq 0 ] && exit 0

# Sort window IDs by session display index for stable output order.
sort_by_session_idx() {
  local -n _map=$1
  for wid in "${!_map[@]}"; do
    sid="${_map[$wid]#\$}"
    printf '%d\t%s\n' "${session_display_idx[$sid]:-0}" "$wid"
  done | sort -n | cut -f2
}

thinking_out=""
idx=0
while IFS= read -r window_id; do
  label="${thinking_labels[$window_id]}"
  color="${thinking_colors[$((idx % 2))]}"
  thinking_out="${thinking_out}${color} 💭 ${label} "
  idx=$((idx + 1))
done < <(sort_by_session_idx thinking_windows)

long_out=""
short_out=""
long_width=0
idx=0
while IFS= read -r window_id; do
  label="${idle_labels[$window_id]}"
  color="${idle_colors[$((idx % 2))]}"
  long_out="${long_out}${color} ! ${label} "
  short_out="${short_out}${color} ! ${idle_short_labels[$window_id]} "
  long_width=$((long_width + ${#label} + 5))
  idx=$((idx + 1))
done < <(sort_by_session_idx idle_windows)

if [ "${#idle_windows[@]}" -eq 0 ]; then
  printf ' %s ' "$thinking_out"
  exit 0
fi

client_width=$("$TMUX_BIN" display -p '#{client_width}' 2>/dev/null || echo 200)
win_list_width=0
while IFS= read -r wname; do
  win_list_width=$((win_list_width + ${#wname} + 5))
done < <("$TMUX_BIN" list-windows -F "#{window_name}" 2>/dev/null)
available=$((client_width - 48 - win_list_width - 25))

if [ "$long_width" -le "$available" ]; then
  printf ' %s%s ' "$thinking_out" "$long_out"
else
  printf ' %s%s ' "$thinking_out" "$short_out"
fi
