#!/usr/bin/env bash
# Drive a Bluetooth scan from the popup: show a "scanning…" spinner, run the ~8s scan,
# publish the discovered devices, then clear the flag.
#
# Runs DETACHED (setsid) with a `trap … EXIT` that clears bt_scanning on ANY exit —
# otherwise eww tearing down this onclick child mid-scan (popup closed, or the button
# re-clicked) left bt_scanning stuck `true` and the button was permanently "scanning…".
# Same fix already used by wifi-rescan.sh / wifi-toggle.
d="$(dirname "$0")"
setsid -f bash -c '
  d="$1"
  trap "eww update bt_scanning=false >/dev/null 2>&1 || true" EXIT
  eww update bt_scanning=true >/dev/null 2>&1 || true
  eww update bt_scan="$("$d/bt-scan.sh")" >/dev/null 2>&1 || true
' _ "$d" >/dev/null 2>&1 || true
