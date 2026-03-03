#!/bin/bash
for s in $(tmux list-sessions -F '#{session_name}'); do
  path=$(tmux display-message -p -t "$s:" '#{pane_current_path}' 2>/dev/null) || continue
  if branch=$(cd "$path" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null) && [ -n "$branch" ]; then
    tmux set-option -qt "$s" @git_branch "$branch"
  else
    tmux set-option -qut "$s" @git_branch
  fi
done
