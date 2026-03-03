#!/bin/bash
sel=$(tmux list-sessions -F '#{session_name}' | while read -r s; do
  path=$(tmux display-message -p -t "$s:" '#{pane_current_path}' 2>/dev/null)
  wins=$(tmux display-message -p -t "$s:" '#{session_windows}' 2>/dev/null)
  att=$(tmux display-message -p -t "$s:" '#{session_attached}' 2>/dev/null)
  branch=$(cd "$path" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
  printf '%s  (%s windows)' "$s" "$wins"
  [ -n "$branch" ] && printf '  [%s]' "$branch"
  [ "$att" = "1" ] && printf '  (attached)'
  printf '\n'
done | fzf --reverse --no-sort --header='Switch Session')

[ -n "$sel" ] && tmux switch-client -t "$(echo "$sel" | awk '{print $1}')"
