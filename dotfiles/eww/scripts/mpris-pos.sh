#!/usr/bin/env bash
# Playback position for the seek bar, polled every 1s (kept out of mpris.sh so
# metadata isn't re-read each tick). Emits JSON: {sec} for the scale value, {str}
# (m:ss) for the elapsed label.
command -v playerctl >/dev/null 2>&1 || { echo '{"sec":0,"str":"0:00"}'; exit 0; }
p=$(playerctl position 2>/dev/null); p=${p%.*}; p=${p:-0}
printf '{"sec":%d,"str":"%d:%02d"}\n' "$p" "$((p/60))" "$((p%60))"
