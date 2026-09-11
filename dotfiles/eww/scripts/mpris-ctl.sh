#!/usr/bin/env bash
# Media transport controls for the eww music popup. Args: toggle | next | prev.
# These are instant playerctl calls that DON'T close the popup or rebuild widgets,
# so (unlike wifi-connect) they finish before eww could tear down the onclick child —
# no setsid needed.
command -v playerctl >/dev/null 2>&1 || exit 0
case "${1:-}" in
  toggle) playerctl play-pause ;;
  next)   playerctl next ;;
  prev)   playerctl previous ;;
esac >/dev/null 2>&1 || true
