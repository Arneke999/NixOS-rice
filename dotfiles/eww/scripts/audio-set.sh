#!/usr/bin/env bash
# Set the default audio OUTPUT sink (from the volume popup picker), then refresh eww
# so the slider (new sink's volume) and the picker's active marker update at once.
id="${1:-}"; [ -z "$id" ] && exit 0
wpctl set-default "$id" >/dev/null 2>&1 || true
d="$(dirname "$0")"
eww update volume="$("$d/volume.sh")" audio_sinks="$("$d/audio-sinks.sh")" >/dev/null 2>&1 || true
