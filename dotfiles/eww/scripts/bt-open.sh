#!/usr/bin/env bash
# Refresh the paired-device list, then toggle the Bluetooth popup open/closed.
d="$(dirname "$0")"
eww update bt_devices="$("$d/bt-list.sh")" >/dev/null 2>&1 || true
"$d/pop.sh" pop-bt
