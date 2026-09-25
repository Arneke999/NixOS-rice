#!/usr/bin/env bash
# Print the MPRIS player the media controls should act on (empty = playerctl default).
# Shared by media-ctl.sh (buttons/keys), mpris.sh (bar widget) and mpris-pos.sh (seek
# bar) so what the bar SHOWS is always what the buttons CONTROL. Plain `playerctl`
# just takes the first player it lists — with Spotify + a Brave tab open that's often
# a paused one. Priority:
#   1. a player that is currently Playing
#   2. playerctld's most recently active player
t="$(playerctl -a metadata --format '{{playerInstance}} {{status}}' 2>/dev/null \
     | awk '$2=="Playing"{print $1; exit}')"
if [ -z "$t" ] && playerctl -p playerctld status >/dev/null 2>&1; then t=playerctld; fi
printf '%s' "$t"
