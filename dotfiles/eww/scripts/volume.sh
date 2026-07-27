#!/usr/bin/env bash
# Volume state as JSON: {"muted":bool,"value":N}. (Was a bare string; JSON keeps
# the number a real number so the popup slider can bind to it cleanly.)
line=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || { echo '{"muted":false,"value":0}'; exit 0; }
if [[ $line == *MUTED* ]]; then muted=true; else muted=false; fi
val=$(awk '{printf "%d", $2*100}' <<<"$line")
printf '{"muted":%s,"value":%s}\n' "$muted" "${val:-0}"
