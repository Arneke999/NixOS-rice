#!/usr/bin/env bash
# Scan for nearby Bluetooth devices and emit the UNPAIRED, named ones as JSON for the
# popup's "pair new" list: [{mac,name}]. (Already-paired devices live in bt_devices via
# bt-list.sh.) Named-only so the list isn't full of anonymous MACs.
#
# Two things that made AirPods (and other slow-to-appear BLE devices) never show up:
#   1. The scan was only 8s — on this adapter AirPods can take >8s to be discovered.
#   2. It listed devices AFTER the scan stopped, but BlueZ PURGES discovered-but-unpaired
#      devices seconds after a scan ends, so a late arrival vanished before being listed.
# Fix: keep the scan ACTIVE (background it), give it ~12s, and list WHILE it's running.
command -v bluetoothctl >/dev/null || { echo '[]'; exit 0; }

# Background a TIMED scan: its lifetime is driven by --timeout, so it keeps the adapter
# discovering for the full window even without a tty. (A plain backgrounded `scan on`
# exits immediately and never actually scans.) We then list devices WHILE it's still
# active — before BlueZ purges unpaired ones when the scan stops.
bluetoothctl --timeout 14 scan on >/dev/null 2>&1 &
scanpid=$!
sleep 12                                                # let slow BLE devices (AirPods) appear
paired="$(timeout 2 bluetoothctl devices Paired 2>/dev/null | awk '{print $2}')"
devs="$(timeout 3 bluetoothctl devices 2>/dev/null)"   # listed while scan still active → no purge
wait "$scanpid" 2>/dev/null                            # let the scan finish (turns itself off)

out=""
while read -r _ mac name; do
  [ -z "$mac" ] && continue
  grep -qw "$mac" <<<"$paired" && continue      # skip already-paired
  # Named devices only:
  [ -z "$name" ] && continue                    # skip unnamed
  [ "$name" = "$mac" ] && continue              # skip name == raw MAC (aa:bb:…)
  [ "$name" = "${mac//:/-}" ] && continue       # skip name == MAC-with-dashes (aa-bb-…)
  name=${name//\"/}; name=${name//\\/}
  out+="{\"mac\":\"$mac\",\"name\":\"$name\"},"
done <<< "$devs"
echo "[${out%,}]"
