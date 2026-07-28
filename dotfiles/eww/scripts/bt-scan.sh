#!/usr/bin/env bash
# Scan ~8s for nearby Bluetooth devices and emit the UNPAIRED, named ones as JSON for
# the popup's "pair new" list: [{mac,name}]. (Already-paired devices live in
# bt_devices via bt-list.sh.) Named-only so the list isn't full of anonymous MACs.
command -v bluetoothctl >/dev/null || { echo '[]'; exit 0; }
timeout 9 bluetoothctl --timeout 8 scan on >/dev/null 2>&1 || true

paired="$(timeout 2 bluetoothctl devices Paired 2>/dev/null | awk '{print $2}')"
out=""
while read -r _ mac name; do
  [ -z "$mac" ] && continue
  grep -qw "$mac" <<<"$paired" && continue      # skip already-paired
  [ -z "$name" ] || [ "$name" = "$mac" ] && continue   # named devices only
  name=${name//\"/}; name=${name//\\/}
  out+="{\"mac\":\"$mac\",\"name\":\"$name\"},"
done < <(timeout 2 bluetoothctl devices 2>/dev/null)
echo "[${out%,}]"
