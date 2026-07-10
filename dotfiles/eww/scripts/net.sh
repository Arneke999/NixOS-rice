#!/usr/bin/env bash
# Reactive network status: wifi glyph by signal, wired, or off.
state=$(nmcli -t -f TYPE,STATE dev status 2>/dev/null | awk -F: '$2=="connected"{print $1; exit}')
case "$state" in
  wifi)
    sig=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '/^\*/{print $2; exit}')
    sig=${sig:-0}
    if   (( sig >= 80 )); then icon="󰤨"
    elif (( sig >= 55 )); then icon="󰤥"
    elif (( sig >= 30 )); then icon="󰤢"
    elif (( sig >=  5 )); then icon="󰤟"
    else                       icon="󰤯"; fi
    echo "$icon ${sig}%"
    ;;
  ethernet) echo "󰈀 wired" ;;
  *)        echo "󰤭 off" ;;
esac
