#!/usr/bin/env bash
# Speaker/output mute toggle. active (true) = audio ON (not muted).
case "$1" in
  toggle) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  status) wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED" && echo false || echo true ;;
esac
