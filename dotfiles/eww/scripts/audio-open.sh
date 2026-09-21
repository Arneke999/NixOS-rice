#!/usr/bin/env bash
# Refresh the audio sink list, then toggle the volume popup (mirrors wifi-open.sh so
# the device picker is current every time the popup opens).
d="$(dirname "$0")"
eww update audio_sinks="$("$d/audio-sinks.sh")" >/dev/null 2>&1 || true
"$d/pop.sh" pop-audio
