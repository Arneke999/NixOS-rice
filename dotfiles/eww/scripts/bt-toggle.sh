#!/usr/bin/env bash
# Toggle bluetooth adapter power.
command -v bluetoothctl >/dev/null || exit 0
if timeout 2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
  timeout 2 bluetoothctl power off
else
  timeout 2 bluetoothctl power on
fi
