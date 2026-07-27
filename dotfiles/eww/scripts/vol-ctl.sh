#!/usr/bin/env bash
# Change the default sink volume (or mute), then immediately push the new state to
# eww so the bar updates instantly instead of waiting for the next poll.
# Args: up | down | mute | set <pct>. Called from the eww bar AND Hyprland keys.
dir="${1:-}"; val="${2:-}"
step=5
sink="@DEFAULT_AUDIO_SINK@"
case "$dir" in
  up)   wpctl set-volume -l 1.0 "$sink" "${step}%+" ;;   # -l 1.0 caps at 100%
  down) wpctl set-volume "$sink" "${step}%-" ;;
  mute) wpctl set-mute "$sink" toggle ;;
  set)  [ -n "$val" ] && wpctl set-volume -l 1.0 "$sink" "${val}%" ;;
esac >/dev/null 2>&1
eww update volume="$("$(dirname "$0")/volume.sh")" >/dev/null 2>&1 || true
