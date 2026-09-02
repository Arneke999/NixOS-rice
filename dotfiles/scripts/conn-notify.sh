#!/usr/bin/env bash
# Fires a desktop notification when a Wi-Fi network or a Bluetooth device connects.
#
# Polls authoritative nmcli / bluetoothctl state every few seconds and diffs against
# the last sample — deliberately simple and locale-independent (no parsing of
# `nmcli monitor` / `dbus-monitor` text, which is human-readable and fragile). The
# cadence matches eww's existing pollers, so this adds no meaningful cost.
#
# State is SEEDED before the loop, so whatever is already connected at login does not
# toast — only genuinely new connections after startup do. Autostarted via hyprland
# exec-once. Success Wi-Fi toasts here replace the ones wifi-connect.sh used to send,
# so a UI connect notifies exactly once.
set -uo pipefail

# Single instance: a new start (e.g. next login's exec-once) replaces the old one,
# so pollers never stack up and double-toast.
PIDF="$HOME/.cache/hypr/conn-notify.pid"; mkdir -p "$(dirname "$PIDF")"
if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; then
  kill "$(cat "$PIDF")" 2>/dev/null || true
fi
echo $$ > "$PIDF"

wifi_ssid()    { nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}'; }
bt_connected() { bluetoothctl devices Connected 2>/dev/null | sed -n 's/^Device [0-9A-F:]\{17\} //p' | sort; }

last_ssid="$(wifi_ssid)"
last_bt="$(bt_connected)"

while sleep 4; do
  # ── Wi-Fi ──────────────────────────────────────────────────────────────────
  ssid="$(wifi_ssid)"
  if [ "$ssid" != "$last_ssid" ]; then
    [ -n "$ssid" ] && notify-send -a "Network" -t 3500 "󰤨  Wi-Fi connected" "$ssid"
    last_ssid="$ssid"
  fi

  # ── Bluetooth ──────────────────────────────────────────────────────────────
  bt="$(bt_connected)"
  if [ "$bt" != "$last_bt" ]; then
    # Toast each device that appeared in the connected set since last sample.
    while IFS= read -r dev; do
      [ -n "$dev" ] && notify-send -a "Bluetooth" -t 3500 "󰂱  Bluetooth connected" "$dev"
    done < <(comm -13 <(printf '%s\n' "$last_bt") <(printf '%s\n' "$bt"))
    last_bt="$bt"
  fi
done
