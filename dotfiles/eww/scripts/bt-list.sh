#!/usr/bin/env bash
# Paired Bluetooth devices as a JSON array for the popup, each with its connection
# state so the popup can offer one-click (re)connect/disconnect. Refreshed on
# demand (popup open / toggle / connect), not polled, to avoid constant bluetoothctl
# spawns on the bar.
command -v bluetoothctl >/dev/null || { echo '[]'; exit 0; }
out=""
while read -r _ mac name; do
  [ -z "$mac" ] && continue
  conn=false
  timeout 2 bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes" && conn=true
  name=${name//\"/}; name=${name//\\/}
  out+="{\"mac\":\"$mac\",\"name\":\"$name\",\"connected\":$conn},"
done < <(timeout 2 bluetoothctl devices Paired 2>/dev/null)
echo "[${out%,}]"
