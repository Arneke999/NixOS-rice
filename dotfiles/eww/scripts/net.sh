#!/usr/bin/env bash
# Compact network status: wifi signal, wired, or off.
state=$(nmcli -t -f TYPE,STATE dev status 2>/dev/null | awk -F: '$2=="connected"{print $1; exit}')
case "$state" in
  wifi)
    sig=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '/^\*/{print $2; exit}')
    echo "  ${sig:-0}%"
    ;;
  ethernet) echo "  wired" ;;
  *)        echo "  off" ;;
esac
