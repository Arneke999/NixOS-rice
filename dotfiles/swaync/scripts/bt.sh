#!/usr/bin/env bash
# Bluetooth power toggle. active (true) = powered on.
command -v bluetoothctl >/dev/null || { [ "$1" = status ] && echo false; exit 0; }
case "$1" in
  toggle)
    if timeout 2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
      timeout 2 bluetoothctl power off >/dev/null 2>&1
    else
      timeout 2 bluetoothctl power on >/dev/null 2>&1
    fi ;;
  status)
    timeout 2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo true || echo false ;;
esac
