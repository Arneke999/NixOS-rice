#!/usr/bin/env bash
# Paired Bluetooth devices as JSON for the popup: [{mac,name,connected,battery}].
# `battery` = charge % from BlueZ's org.bluez.Battery1 (-1 when the device doesn't
# report one). Refreshed on demand (popup open / toggle / connect), not polled.
#
# NOTE: AirPods report battery over Apple's PROPRIETARY BLE protocol, which BlueZ
# can't read — so they usually come back battery=-1 here. Standard headsets that use
# the normal HFP/Battery indicator do report a %.
command -v bluetoothctl >/dev/null || { echo '[]'; exit 0; }
out=""
while read -r _ mac name; do
  [ -z "$mac" ] && continue
  info=$(timeout 2 bluetoothctl info "$mac" 2>/dev/null)
  conn=false; grep -q "Connected: yes" <<<"$info" && conn=true
  # "Battery Percentage: 0x64 (100)" → 100 ; empty → -1
  bat=$(awk -F'[()]' '/Battery Percentage:/{print $2; exit}' <<<"$info"); bat=${bat:--1}
  name=${name//\"/}; name=${name//\\/}
  out+="{\"mac\":\"$mac\",\"name\":\"$name\",\"connected\":$conn,\"battery\":$bat},"
done < <(timeout 2 bluetoothctl devices Paired 2>/dev/null)
echo "[${out%,}]"
