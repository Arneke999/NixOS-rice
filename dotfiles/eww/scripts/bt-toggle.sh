#!/usr/bin/env bash
# Toggle bluetooth adapter power, then refresh the eww widgets.
command -v bluetoothctl >/dev/null || exit 0
if timeout 2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
  timeout 2 bluetoothctl power off
else
  timeout 2 bluetoothctl power on
fi
d="$(dirname "$0")"
eww update bluetooth="$("$d/bluetooth.sh")" bt_devices="$("$d/bt-list.sh")" >/dev/null 2>&1 || true
