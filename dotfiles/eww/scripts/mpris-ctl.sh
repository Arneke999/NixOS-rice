#!/usr/bin/env bash
# Media transport controls for the eww music popup. Args: toggle | next | prev.
# Delegates to media-ctl.sh so the popup buttons, the keyboard media keys and headset
# buttons (AirPods etc.) all pick the SAME player (the one actually playing).
d="$(dirname "$0")"
case "${1:-}" in
  toggle) "$d/media-ctl.sh" play-pause ;;
  next)   "$d/media-ctl.sh" next ;;
  prev)   "$d/media-ctl.sh" previous ;;
esac
