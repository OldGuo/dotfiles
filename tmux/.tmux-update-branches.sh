#!/bin/bash
# Use the same tmux binary as the running server (snap vs system).
TMUX_BIN="$(readlink -f "/proc/$(echo "$TMUX" | cut -d, -f2)/exe" 2>/dev/null || echo tmux)"

# Snap updates can wipe the private /tmp that holds the socket.
# Recreate the directory so the server can re-bind.
if [ -n "$TMUX" ]; then
  _socket_dir="$(dirname "${TMUX%%,*}")"
  [ -d "$_socket_dir" ] || mkdir -p "$_socket_dir" 2>/dev/null
fi
for s in $("$TMUX_BIN" list-sessions -F '#{session_name}'); do
  path=$("$TMUX_BIN" display-message -p -t "$s:" '#{pane_current_path}' 2>/dev/null) || continue
  if branch=$(cd "$path" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null) && [ -n "$branch" ]; then
    "$TMUX_BIN" set-option -qt "$s" @git_branch "$branch"
  else
    "$TMUX_BIN" set-option -qut "$s" @git_branch
  fi
done
