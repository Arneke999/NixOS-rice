#!/usr/bin/env bash
# Toggle bluetooth adapter power with INSTANT visual feedback.
#
# `bluetoothctl power on/off` takes a beat for the adapter to actually flip, and the
# old version only refreshed the widgets AFTER that (plus a device re-list) — so the
# button lagged. Now we update the UI optimistically the moment the click lands, issue
# the power change, reconcile, and load the device list in the background.
command -v bluetoothctl >/dev/null || exit 0
d="$(dirname "$0")"

if timeout 2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
  # → OFF: flip the UI now, then power off and reconcile.
  eww update bluetooth='{"present":true,"powered":false,"connected":false}' bt_devices='[]' >/dev/null 2>&1 || true
  timeout 5 bluetoothctl power off >/dev/null 2>&1 || true
  eww update bluetooth="$("$d/bluetooth.sh")" >/dev/null 2>&1 || true
else
  # → ON: show "on" now, power on, reconcile, then load paired devices in background.
  eww update bluetooth='{"present":true,"powered":true,"connected":false}' >/dev/null 2>&1 || true
  timeout 5 bluetoothctl power on >/dev/null 2>&1 || true
  eww update bluetooth="$("$d/bluetooth.sh")" >/dev/null 2>&1 || true
  setsid -f bash -c 'eww update bt_devices="$("$1/bt-list.sh")" >/dev/null 2>&1 || true' _ "$d" >/dev/null 2>&1 || true
fi
