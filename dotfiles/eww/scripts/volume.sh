#!/usr/bin/env bash
# Print volume percent, or "muted".
line=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || { echo "0"; exit 0; }
if [[ $line == *MUTED* ]]; then
  echo "muted"
else
  awk '{printf "%d", $2*100}' <<<"$line"
fi
