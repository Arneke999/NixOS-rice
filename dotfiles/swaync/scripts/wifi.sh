#!/usr/bin/env bash
# Wi-Fi radio toggle. active (true) = wifi on.
case "$1" in
  toggle)
    [ "$(nmcli -t radio wifi 2>/dev/null)" = "enabled" ] && nmcli radio wifi off || nmcli radio wifi on ;;
  status)
    [ "$(nmcli -t radio wifi 2>/dev/null)" = "enabled" ] && echo true || echo false ;;
esac
