#!/usr/bin/env bash
# Change backlight brightness, then immediately push the new value to eww so the
# bar updates instantly instead of waiting for the next poll (the old ~3s lag).
# Args: up | down | set <pct>. Called from the eww bar AND Hyprland's XF86 keys.
dir="${1:-}"; val="${2:-}"
step=5
case "$dir" in
  up)   brightnessctl set "${step}%+" ;;
  down) brightnessctl set "${step}%-" ;;
  set)  [ -n "$val" ] && brightnessctl set "${val}%" ;;
esac >/dev/null 2>&1
eww update brightness="$("$(dirname "$0")/brightness.sh")" >/dev/null 2>&1 || true
