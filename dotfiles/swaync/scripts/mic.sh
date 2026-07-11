#!/usr/bin/env bash
# Microphone mute toggle. active (true) = mic ON (not muted).
case "$1" in
  toggle) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
  status) wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q "MUTED" && echo false || echo true ;;
esac
