#!/usr/bin/env bash
set -euo pipefail

if [ -z "${TMUX:-}" ]; then
  echo "tmux btop dashboard must be started from inside tmux" >&2
  exit 1
fi

tmux new-window -n btop 'btop --preset 2'
tmux split-window -v -p 60 'btop --preset 3'
tmux split-window -v -l 8 '~/.tmux-disk-space.sh'
tmux select-pane -U
tmux select-pane -U
