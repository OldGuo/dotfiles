#!/bin/bash
# Use the same tmux binary as the running server when Linux exposes it.
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

# Snap updates can wipe the private /tmp that holds the socket.
# Recreate the directory so the server can re-bind.
if [ -n "$TMUX" ]; then
  _socket_dir="$(dirname "${TMUX%%,*}")"
  [ -d "$_socket_dir" ] || mkdir -p "$_socket_dir" 2>/dev/null
fi
while IFS= read -r s; do
  path=$("$TMUX_BIN" display-message -p -t "$s:" '#{pane_current_path}' 2>/dev/null) || continue
  if branch=$(cd "$path" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null) && [ -n "$branch" ]; then
    "$TMUX_BIN" set-option -qt "$s" @git_branch "$branch"
  else
    "$TMUX_BIN" set-option -qut "$s" @git_branch
  fi
done < <("$TMUX_BIN" list-sessions -F '#{session_name}')
