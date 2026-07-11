#!/usr/bin/env bash
# Flight mode: toggle all NetworkManager radios (wifi/wwan) + bluetooth.
# active (true) = flight mode ON (radios off).
case "$1" in
  toggle)
    if [ "$(nmcli -t radio wifi 2>/dev/null)" = "enabled" ]; then
      nmcli radio all off
      command -v bluetoothctl >/dev/null && timeout 2 bluetoothctl power off >/dev/null 2>&1
    else
      nmcli radio all on
    fi ;;
  status)
    [ "$(nmcli -t radio wifi 2>/dev/null)" = "enabled" ] && echo false || echo true ;;
esac
