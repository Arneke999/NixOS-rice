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

# Pairable ON is what makes the pairing a *bond* (link key written to disk). With it
# off, BlueZ does a non-bonding pairing: works until the next reboot, then fails with
# br-connection-key-missing. That was the "trusted but never reconnects" bug.
timeout 5 bluetoothctl pairable on >/dev/null 2>&1

# A known-but-unbonded record (stale key) makes pairing fail — start clean.
if timeout 2 bluetoothctl info "$mac" 2>/dev/null | grep -q "Bonded: no" \
   && timeout 2 bluetoothctl info "$mac" 2>/dev/null | grep -q "Paired: yes"; then
  timeout 5 bluetoothctl remove "$mac" >/dev/null 2>&1
fi

# Hold the adapter in discovery so the target stays in BlueZ's cache while we pair,
# and wait (up to 12s) until it's actually visible rather than a fixed sleep.
bluetoothctl --timeout 40 scan on >/dev/null 2>&1 &
scanpid=$!
for _ in $(seq 12); do
  timeout 2 bluetoothctl devices 2>/dev/null | grep -qi "$mac" && break; sleep 1
done

timeout 25 bluetoothctl pair "$mac"  >/dev/null 2>&1
timeout 5  bluetoothctl trust "$mac" >/dev/null 2>&1   # trust → auto-reconnect next time
timeout 15 bluetoothctl connect "$mac" >/dev/null 2>&1

kill "$scanpid" 2>/dev/null
info="$(timeout 2 bluetoothctl info "$mac" 2>/dev/null)"
name="$(sed -n 's/^\tName: //p' <<<"$info")"
# Verify the thing that actually matters: a stored bond.
if grep -q "Bonded: yes" <<<"$info"; then
  note "󰂱  Paired & saved" "${name:-$mac} will reconnect automatically"
elif grep -q "Connected: yes" <<<"$info"; then
  note "Connected, but NOT saved" "${name:-$mac}: put it in pairing mode and pair again"
else
  note "Pairing failed" "${name:-$mac}: put it in pairing mode (hold the case button) and retry"
fi

eww update bt_devices="$("$d/bt-list.sh")" bt_scan='[]' bluetooth="$("$d/bluetooth.sh")" >/dev/null 2>&1 || true
setsid -f "$d/reflow.sh" pop-bt >/dev/null 2>&1   # re-fit popup: device moved from nearby → paired
