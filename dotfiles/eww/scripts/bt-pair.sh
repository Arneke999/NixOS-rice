#!/usr/bin/env bash
# Pair + trust + connect a freshly-discovered device, then refresh the popup (moving
# it out of the scan list into the paired list). Arg: MAC.
mac="${1:-}"; [ -z "$mac" ] && exit 0
d="$(dirname "$0")"
note() { command -v notify-send >/dev/null 2>&1 && notify-send "Bluetooth" "$1"; }

timeout 20 bluetoothctl pair "$mac"    >/dev/null 2>&1
timeout 5  bluetoothctl trust "$mac"   >/dev/null 2>&1
if timeout 15 bluetoothctl connect "$mac" >/dev/null 2>&1; then note "Paired $mac"; else note "Pairing/connect failed: $mac"; fi

eww update bt_devices="$("$d/bt-list.sh")" bt_scan='[]' bluetooth="$("$d/bluetooth.sh")" >/dev/null 2>&1 || true
