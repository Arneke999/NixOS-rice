#!/usr/bin/env bash
# Media transport for headset buttons (AVRCP), keyboard media keys and the eww popup.
# Args: play-pause | next | previous | stop | seek+ | seek-
#
# Target choice matters with several players open (Spotify + a Brave tab): plain
# `playerctl` just grabs the FIRST player it lists, which may be a paused one. So:
#   1. whatever is currently Playing  (squeeze → pauses what you're hearing)
#   2. else playerctld's most recently active player (squeeze again → resumes it)
#   3. else playerctl's default
command -v playerctl >/dev/null 2>&1 || exit 0
target="$("$(dirname "$0")/media-target.sh")"
p=(); [ -n "$target" ] && p=(-p "$target")
case "${1:-}" in
  play-pause) playerctl "${p[@]}" play-pause ;;
  next)       playerctl "${p[@]}" next ;;
  previous)   playerctl "${p[@]}" previous ;;
  stop)       playerctl "${p[@]}" stop ;;
  seek+)      playerctl "${p[@]}" position 10+ ;;
  seek-)      playerctl "${p[@]}" position 10- ;;
esac >/dev/null 2>&1 || true
