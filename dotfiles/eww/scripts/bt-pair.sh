#!/usr/bin/env bash
# Pair + trust + connect a freshly-discovered device, then refresh the popup (moving it
# from the scan list into the paired list). Arg: MAC.
#
# Two fixes over the naive version:
#   • Keeps a scan ACTIVE during pairing — BlueZ purges discovered-but-unpaired devices
#     when scanning stops, so pairing a device from the scan list otherwise fails with
#     "Device … not available".
#   • Runs DETACHED (setsid) so eww tearing down this onclick child mid-pair (popup
#     close / list rebuild) can't abort the ~20s pair. Same pattern as wifi-connect.sh.
mac="${1:-}"; [ -z "$mac" ] && exit 0
d="$(dirname "$0")"

if [ "${BT_PAIR_DETACHED:-}" != 1 ]; then
  setsid -f env BT_PAIR_DETACHED=1 "$0" "$mac" >/dev/null 2>&1 || true
  exit 0
fi

note() { command -v notify-send >/dev/null 2>&1 && notify-send -a "Bluetooth" "$@"; }

# Hold the adapter in discovery so the target stays in BlueZ's cache while we pair.
bluetoothctl --timeout 30 scan on >/dev/null 2>&1 &
scanpid=$!
sleep 2   # give it a moment to (re)discover the device before pairing

timeout 20 bluetoothctl pair "$mac"  >/dev/null 2>&1
timeout 5  bluetoothctl trust "$mac" >/dev/null 2>&1   # trust → auto-reconnect next time
ok=1; timeout 15 bluetoothctl connect "$mac" >/dev/null 2>&1 || ok=0

kill "$scanpid" 2>/dev/null
name="$(timeout 2 bluetoothctl info "$mac" 2>/dev/null | sed -n 's/^\tName: //p')"
if [ "$ok" = 1 ]; then note "󰂱  Connected" "${name:-$mac}"; else note "Pairing/connect failed" "${name:-$mac}"; fi

eww update bt_devices="$("$d/bt-list.sh")" bt_scan='[]' bluetooth="$("$d/bluetooth.sh")" >/dev/null 2>&1 || true
