#!/usr/bin/env bash
# Connect/disconnect a paired device (toggle by current state), then refresh eww.
mac="${1:-}"; [ -z "$mac" ] && exit 0
if timeout 2 bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
  timeout 6 bluetoothctl disconnect "$mac"
else
  timeout 10 bluetoothctl connect "$mac"
fi
d="$(dirname "$0")"
eww update bt_devices="$("$d/bt-list.sh")" bluetooth="$("$d/bluetooth.sh")" >/dev/null 2>&1 || true
