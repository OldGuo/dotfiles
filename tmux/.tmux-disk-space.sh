#!/usr/bin/env bash
set -euo pipefail

if df -h -x tmpfs -x devtmpfs -x squashfs >/dev/null 2>&1; then
  df_cmd=(df -h -x tmpfs -x devtmpfs -x squashfs)
else
  df_cmd=(df -h)
fi

while true; do
  clear
  printf 'Disk space (%s)\n' "$(date +%H:%M:%S)"
  "${df_cmd[@]}" | awk 'NR == 1 || $NF == "/" || $NF ~ "^/(home|boot|mnt|media|Volumes)(/|$)"'
  sleep 5
done
