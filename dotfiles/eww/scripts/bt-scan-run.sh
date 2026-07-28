#!/usr/bin/env bash
# Drive a scan from the popup: flip the "scanning…" flag, run the ~8s scan, publish
# the discovered devices, then clear the flag.
d="$(dirname "$0")"
eww update bt_scanning=true                        >/dev/null 2>&1 || true
eww update bt_scan="$("$d/bt-scan.sh")"            >/dev/null 2>&1 || true
eww update bt_scanning=false                       >/dev/null 2>&1 || true
