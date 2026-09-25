#!/usr/bin/env bash
# Toggle the bluetooth adapter with instant visual feedback.
#
# On power-ON it now also, in the background:
#   • reconnects every KNOWN (paired) device — BlueZ links up the trusted ones that
#     are in range, so your headphones/etc. come back on their own;
#   • kicks off a scan so nearby devices appear immediately (spinner via bt_scanning),
#     instead of a dead "no devices found".
# So turning Bluetooth on "just works": known devices reconnect, new ones show up.
command -v bluetoothctl >/dev/null || exit 0
d="$(dirname "$0")"

if timeout 2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
  # → OFF: flip the UI now, power off, reconcile.
  eww update bluetooth='{"present":true,"powered":false,"connected":false}' \
             bt_devices='[]' bt_scan='[]' bt_scanning=false >/dev/null 2>&1 || true
  timeout 5 bluetoothctl power off >/dev/null 2>&1 || true
  eww update bluetooth="$("$d/bluetooth.sh")" >/dev/null 2>&1 || true
  setsid -f "$d/reflow.sh" pop-bt >/dev/null 2>&1   # shrink popup (lists cleared)
else
  # → ON: optimistic UI, power on, then reconnect + scan in the background.
  eww update bluetooth='{"present":true,"powered":true,"connected":false}' >/dev/null 2>&1 || true
  timeout 5 bluetoothctl power on >/dev/null 2>&1 || true
  eww update bluetooth="$("$d/bluetooth.sh")" >/dev/null 2>&1 || true
  # Detached (setsid) so eww tearing down the onclick child can't abort it; trap clears
  # the scanning spinner on any exit.
  setsid -f bash -c '
    d="$1"
    trap "eww update bt_scanning=false >/dev/null 2>&1 || true" EXIT
    sleep 1                                          # let the adapter settle after power-on
    # Reconnect known devices (trusted + in range link up; harmless when absent).
    while read -r _ mac _; do
      [ -n "$mac" ] && timeout 8 bluetoothctl connect "$mac" >/dev/null 2>&1 &
    done < <(timeout 3 bluetoothctl devices Paired 2>/dev/null)
    eww update bt_devices="$("$d/bt-list.sh")" >/dev/null 2>&1 || true
    "$d/reflow.sh" pop-bt   # show paired devices at the right size
    # Auto-scan so nearby/new devices appear without hitting the Scan button.
    eww update bt_scanning=true >/dev/null 2>&1 || true
    eww update bt_scan="$("$d/bt-scan.sh")" bt_devices="$("$d/bt-list.sh")" \
               bluetooth="$("$d/bluetooth.sh")" >/dev/null 2>&1 || true
    "$d/reflow.sh" pop-bt   # grow to fit scan results
  ' _ "$d" >/dev/null 2>&1 || true
fi
